#!/usr/bin/env python3
"""
L1 — Exact-match cache (Redis).

The fast path: normalize the query, hash it, and look for an exact
previous answer. No embeddings, no Postgres — just a key/value lookup
with a TTL.

Run this file directly for a standalone demo of just the Redis layer:
    python l1_cache.py

Required environment variables:
    REDIS_HOST, REDIS_PORT, REDIS_KEY

Optional:
    CACHE_TTL_SECONDS   default 3600
"""

import hashlib
import os
import re
import sys

import redis

from dotenv import load_dotenv

load_dotenv()

def require_env(name, default=None, cast=str):
    raw = os.environ.get(name, default)
    if raw is None:
        sys.exit(f"ERROR: required environment variable {name} is not set")
    try:
        return cast(raw)
    except ValueError:
        sys.exit(f"ERROR: environment variable {name}={raw!r} is not a valid {cast.__name__}")


REDIS_HOST = require_env("REDIS_HOST")
REDIS_PORT = require_env("REDIS_PORT", cast=int)
REDIS_KEY = require_env("REDIS_KEY")
CACHE_TTL_SECONDS = require_env("CACHE_TTL_SECONDS", default="3600", cast=int)


def normalize_query(text):
    """Lowercase, strip punctuation, collapse whitespace, so 'Good webcam?'
    and 'good webcam' hash to the same cache key."""
    text = text.lower()
    text = re.sub(r"[^\w\s]", "", text)
    return " ".join(text.split())


def exact_cache_key(normalized_query):
    digest = hashlib.md5(normalized_query.encode("utf-8")).hexdigest()
    return f"exactcache:{digest}"


class ExactCache:
    """Thin wrapper around Redis for the L1 exact-match layer."""

    def __init__(self, client=None):
        self.client = client or redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            password=REDIS_KEY,
            ssl=True,
            decode_responses=True,
        )

    def get(self, query_text):
        key = exact_cache_key(normalize_query(query_text))
        return self.client.get(key)

    def set(self, query_text, response_text, ttl=None):
        key = exact_cache_key(normalize_query(query_text))
        self.client.set(key, response_text, ex=ttl or CACHE_TTL_SECONDS)

    def flush(self):
        self.client.flushdb()


if __name__ == "__main__":
    # Standalone demo: no embeddings, no Postgres. Just Redis hit/miss/TTL,
    # so this layer is visible in isolation before L2 is introduced.
    cache = ExactCache()
    print("L1 exact-cache demo. Type 'done' to quit, 'flush' to clear cache.\n")

    while True:
        query = input("Ask a question: ").strip()
        if query.lower() == "done":
            break
        if query.lower() == "flush":
            cache.flush()
            print("Cache cleared.\n")
            continue
        if not query:
            continue

        hit = cache.get(query)
        if hit:
            print(f"HIT  -> {hit}\n")
            continue

        print("MISS -> not cached yet.")
        answer = input("Type the answer to store for this question: ").strip()
        cache.set(query, answer)
        print("Stored. Ask the exact same question again to see a HIT.\n")
