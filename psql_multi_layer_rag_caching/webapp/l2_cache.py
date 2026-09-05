#!/usr/bin/env python3
"""
L2 — Semantic cache (PostgreSQL + pgvector), plus the product-review
vector search it falls back to on a full miss.

This layer understands meaning, not just exact text: "good webcam for
zoom" and "works well for video calls" can hit the same cached answer
if their embeddings are close enough.

Run this file directly for a standalone demo of just the embedding +
pgvector layer (no Redis involved):
    python l2_cache.py

Required environment variables:
    PG_HOST, PG_ADMIN_USER, PG_PASSWORD (or PGPASSWORD), DB_NAME
    OPENAI_EMBED_DEPLOYMENT   deployment name, e.g. text-embedding-3-small
    OPENAI_ENDPOINT           e.g. https://<resource>.openai.azure.com

Optional:
    OPENAI_API_KEY       if unset, falls back to Microsoft Entra ID
    OPENAI_API_VERSION   default 2024-10-21
    EMBED_DIM            default 1536 (text-embedding-3-small's native size)
    SEMANTIC_THRESHOLD   default 0.85
"""

import os
import sys

import psycopg
from openai import AzureOpenAI


def require_env(name, default=None, cast=str):
    raw = os.environ.get(name, default)
    if raw is None:
        sys.exit(f"ERROR: required environment variable {name} is not set")
    try:
        return cast(raw)
    except ValueError:
        sys.exit(f"ERROR: environment variable {name}={raw!r} is not a valid {cast.__name__}")


PG_HOST = require_env("PG_HOST")
PG_ADMIN_USER = require_env("PG_ADMIN_USER")
PG_PASSWORD = os.environ.get("PGPASSWORD") or os.environ.get("PG_PASSWORD")
if not PG_PASSWORD:
    sys.exit("ERROR: set PGPASSWORD or PG_PASSWORD")
DB_NAME = require_env("DB_NAME")

OPENAI_EMBED_DEPLOYMENT = require_env("OPENAI_EMBED_DEPLOYMENT")
OPENAI_ENDPOINT = require_env("OPENAI_ENDPOINT")
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")  # optional; else Entra ID
OPENAI_API_VERSION = os.environ.get("OPENAI_API_VERSION", "2024-10-21")

EMBED_DIM = require_env("EMBED_DIM", default="1536", cast=int)
SEMANTIC_THRESHOLD = require_env("SEMANTIC_THRESHOLD", default="0.85", cast=float)


def build_pg_conn():
    return psycopg.connect(
        host=PG_HOST,
        user=PG_ADMIN_USER,
        password=PG_PASSWORD,
        dbname=DB_NAME,
        sslmode="require",
        autocommit=True,
    )


def build_openai_client():
    if OPENAI_API_KEY:
        return AzureOpenAI(
            azure_endpoint=OPENAI_ENDPOINT,
            api_key=OPENAI_API_KEY,
            api_version=OPENAI_API_VERSION,
        )

    # Entra ID (recommended): avoids a long-lived key in the environment.
    from azure.identity import DefaultAzureCredential, get_bearer_token_provider
    token_provider = get_bearer_token_provider(
        DefaultAzureCredential(), "https://ai.azure.com/.default"
    )
    return AzureOpenAI(
        azure_endpoint=OPENAI_ENDPOINT,
        azure_ad_token_provider=token_provider,
        api_version=OPENAI_API_VERSION,
    )


def generate_embedding(openai_client, text):
    response = openai_client.embeddings.create(model=OPENAI_EMBED_DEPLOYMENT, input=text)
    return response.data[0].embedding


def vector_literal(embedding):
    """Format a Python list of floats as a pgvector literal, e.g. '[0.1,0.2,...]'."""
    return "[" + ",".join(repr(x) for x in embedding) + "]"


class SemanticCache:
    """Postgres/pgvector-backed L2 cache: similarity lookup + storage."""

    def __init__(self, conn=None):
        self.conn = conn or build_pg_conn()
        self._ensure_schema()

    def _ensure_schema(self):
        with self.conn.cursor() as cur:
            cur.execute(f"""
                CREATE TABLE IF NOT EXISTS semantic_cache (
                    cache_id BIGSERIAL PRIMARY KEY,
                    query_text TEXT NOT NULL,
                    response_text TEXT NOT NULL,
                    query_embedding VECTOR({EMBED_DIM}),
                    created_at TIMESTAMP DEFAULT NOW()
                );
            """)
            cur.execute("""
                CREATE INDEX IF NOT EXISTS semantic_cache_embedding_idx
                ON semantic_cache USING hnsw (query_embedding vector_cosine_ops);
            """)

    def lookup(self, embedding):
        """Return (cache_id, similarity, response_text) for the closest
        stored query, or (None, 0.0, None) if the table is empty."""
        vec = vector_literal(embedding)
        with self.conn.cursor() as cur:
            cur.execute(
                """
                SELECT cache_id, response_text, 1 - (query_embedding <=> %s::vector) AS similarity
                FROM semantic_cache
                ORDER BY query_embedding <=> %s::vector
                LIMIT 1;
                """,
                (vec, vec),
            )
            row = cur.fetchone()
        if row is None:
            return None, 0.0, None
        cache_id, response_text, similarity = row
        return cache_id, float(similarity), response_text

    def is_hit(self, similarity):
        return similarity >= SEMANTIC_THRESHOLD

    def insert(self, query_text, response_text, embedding):
        vec = vector_literal(embedding)
        with self.conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO semantic_cache (query_text, response_text, query_embedding)
                VALUES (%s, %s, %s::vector);
                """,
                (query_text, response_text, vec),
            )

    def search_reviews(self, embedding, limit=5):
        """The fallback vector search that runs on a full cache miss."""
        vec = vector_literal(embedding)
        with self.conn.cursor() as cur:
            cur.execute(
                """
                SELECT r.review_id, r.product_id, r.review_text, r.sentiment_label
                FROM product_reviews r
                JOIN review_embeddings e ON r.review_id = e.review_id
                ORDER BY e.embedding <=> %s::vector
                LIMIT %s;
                """,
                (vec, limit),
            )
            return cur.fetchall()

    def flush(self):
        with self.conn.cursor() as cur:
            cur.execute("TRUNCATE TABLE semantic_cache RESTART IDENTITY;")


if __name__ == "__main__":
    # Standalone demo: embeddings + pgvector similarity only, no Redis.
    openai_client = build_openai_client()
    cache = SemanticCache()
    print("L2 semantic-cache demo. Type 'done' to quit, 'flush' to clear cache.\n")

    while True:
        query = input("Ask a question: ").strip()
        if query.lower() == "done":
            break
        if query.lower() == "flush":
            cache.flush()
            print("Semantic cache cleared.\n")
            continue
        if not query:
            continue

        embedding = generate_embedding(openai_client, query)
        cache_id, similarity, response_text = cache.lookup(embedding)

        if cache_id is not None:
            print(f"Closest match similarity: {similarity:.4f} (threshold {SEMANTIC_THRESHOLD})")

        if cache_id is not None and cache.is_hit(similarity):
            print(f"HIT  -> {response_text}\n")
        else:
            print("MISS -> no close enough match.")
            answer = input("Type the answer to store for this question: ").strip()
            cache.insert(query, answer, embedding)
            print("Stored. Ask something semantically similar to see a HIT.\n")
