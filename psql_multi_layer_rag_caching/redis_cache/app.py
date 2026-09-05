#!/usr/bin/env python3
"""
Full request flow, wiring together L1 (l1_cache.py) and L2 (l2_cache.py):

    User Query -> L1 Redis exact cache -> L2 semantic cache
               -> product review vector search -> save to both caches
               -> return response

Run the two layers separately first to see each mechanism in isolation:
    python l1_cache.py
    python l2_cache.py

Then run this file to see them working together:
    python app.py
    python app.py --flush     # clear both caches and exit
"""

import argparse
import time

from l1_cache import ExactCache
from l2_cache import SemanticCache, build_openai_client, generate_embedding


def format_review_rows(rows):
    return "\n".join(" | ".join(str(col) for col in row) for row in rows)


def print_perf(cache_path, process, embedding_step, vector_search_step,
               elapsed_ms, similarity=None, redis_update=None, semantic_save=None):
    print("\n-------------------------------------------------")
    print("PERFORMANCE DETAILS")
    print("-------------------------------------------------")
    print(f"Cache path    : {cache_path}")
    print(f"Process       : {process}")
    print(f"Embedding     : {embedding_step}")
    print(f"Vector search : {vector_search_step}")
    if redis_update:
        print(f"Redis update  : {redis_update}")
    if semantic_save:
        print(f"Semantic save : {semantic_save}")
    if similarity is not None:
        print(f"Similarity    : {similarity:.4f}")
    print(f"Response time : {elapsed_ms} ms")
    print("-------------------------------------------------")


def run_loop(l1, l2, openai_client):
    while True:
        print()
        try:
            query = input("Ask a question (or 'done'): ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye.")
            break
        if query.lower() == "done":
            print("Goodbye.")
            break
        if not query:
            continue

        start = time.monotonic()

        # ---- L1 ----
        exact_result = l1.get(query)
        if exact_result:
            elapsed_ms = int((time.monotonic() - start) * 1000)
            print("\n=================================================")
            print("L1 EXACT CACHE HIT")
            print("=================================================")
            print(exact_result)
            print_perf("L1 Redis exact cache HIT", "Served directly from Redis",
                       "Skipped", "Skipped", elapsed_ms)
            continue

        # ---- Embedding (shared by the L2 lookup and, on a miss, the review search) ----
        print("\nGenerating embedding...")
        try:
            embedding = generate_embedding(openai_client, query)
        except Exception as exc:
            print(f"\nERROR: Failed to generate embedding: {exc}")
            continue

        # ---- L2 ----
        cache_id, similarity, response_text = l2.lookup(embedding)
        if cache_id is not None and l2.is_hit(similarity):
            l1.set(query, response_text)
            elapsed_ms = int((time.monotonic() - start) * 1000)
            print("\n=================================================")
            print("L2 SEMANTIC CACHE HIT")
            print("=================================================")
            print(f"Similarity: {similarity:.4f}\n")
            print(response_text)
            print_perf("L2 PostgreSQL semantic cache HIT",
                       "Generated embedding, found similar cached query",
                       "Executed", "Skipped main product review vector search",
                       elapsed_ms, similarity=similarity,
                       redis_update="Promoted semantic result into Redis exact cache")
            continue

        # ---- Miss: real vector search ----
        print("\n=================================================")
        print("CACHE MISS")
        print("=================================================")
        rows = l2.search_reviews(embedding)
        fresh_result = format_review_rows(rows)
        print(fresh_result)

        l1.set(query, fresh_result)
        l2.insert(query, fresh_result, embedding)

        elapsed_ms = int((time.monotonic() - start) * 1000)
        print("\nStored in semantic cache.")
        print_perf("MISS", "Recomputed embedding and ran PostgreSQL vector search",
                   "Executed", "Executed against product review embeddings",
                   elapsed_ms, redis_update="Saved result into Redis exact cache",
                   semantic_save="Saved query, response, and embedding into semantic_cache")


def main():
    parser = argparse.ArgumentParser(description="Full L1 -> L2 -> vector search demo")
    parser.add_argument("--flush", action="store_true", help="Clear both caches and exit")
    args = parser.parse_args()

    l1 = ExactCache()
    l2 = SemanticCache()

    if args.flush:
        l1.flush()
        l2.flush()
        print("Redis exact cache and PostgreSQL semantic cache cleared.")
        return

    openai_client = build_openai_client()
    run_loop(l1, l2, openai_client)


if __name__ == "__main__":
    main()
