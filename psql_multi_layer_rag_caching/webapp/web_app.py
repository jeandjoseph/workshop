#!/usr/bin/env python3
"""
Local web front end for the same L1 -> L2 -> vector search cascade as
app.py, served over HTTP instead of a terminal REPL.

Reuses l1_cache.py and l2_cache.py completely unchanged — only the "how
a query comes in and a response goes out" part changes, from stdin/
stdout to an HTTP request/response.

Install and run:
    pip install flask
    python web_app.py
Then open http://127.0.0.1:5000 in a browser.

This is a single-user local demo: one Redis connection and one Postgres
connection are opened at startup and reused for every request. It is
not built for concurrent multi-user traffic — for that you'd want a
connection pool per worker instead of one shared connection.
"""

import time

from flask import Flask, jsonify, render_template_string, request

from l1_cache import ExactCache
from l2_cache import SemanticCache, build_openai_client, generate_embedding

app = Flask(__name__)

l1 = ExactCache()
l2 = SemanticCache()
openai_client = build_openai_client()


PAGE = """
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Semantic Cache Demo</title>
<style>
  body { font-family: system-ui, sans-serif; max-width: 720px; margin: 2rem auto; padding: 0 1rem; color: #222; }
  h1 { font-size: 1.3rem; }
  #query { width: 100%; padding: .6rem; font-size: 1rem; box-sizing: border-box; }
  button { padding: .5rem 1rem; margin-top: .6rem; margin-right: .5rem; font-size: .95rem; cursor: pointer; }
  .badge { display: inline-block; padding: .15rem .6rem; border-radius: .3rem; font-size: .8rem; font-weight: 600; color: white; }
  .L1 { background: #2e7d32; }
  .L2 { background: #1565c0; }
  .MISS { background: #b71c1c; }
  pre { background: #f5f5f5; padding: 1rem; border-radius: .4rem; white-space: pre-wrap; }
  table { border-collapse: collapse; margin-top: .5rem; }
  td { padding: .15rem .6rem .15rem 0; font-size: .9rem; color: #444; }
  #result { margin-top: 1rem; }
</style>
</head>
<body>
  <h1>Semantic Cache Demo</h1>
  <input id="query" placeholder="Ask a question..." autofocus>
  <div>
    <button onclick="ask()">Ask</button>
    <button onclick="flushCaches()">Flush caches</button>
  </div>
  <div id="result"></div>

<script>
async function ask() {
  const box = document.getElementById('query');
  const query = box.value.trim();
  if (!query) return;
  document.getElementById('result').innerHTML = '<p>Working...</p>';
  const res = await fetch('/ask', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({query})
  });
  const data = await res.json();
  render(data);
}

async function flushCaches() {
  await fetch('/flush', {method: 'POST'});
  document.getElementById('result').innerHTML = '<p>Caches cleared.</p>';
}

function render(data) {
  const el = document.getElementById('result');
  if (data.error) {
    el.innerHTML = '<p style="color:#b71c1c">' + data.error + '</p>';
    return;
  }
  let rows = `
    <tr><td>Process</td><td>${data.process}</td></tr>
    <tr><td>Embedding</td><td>${data.embedding_step}</td></tr>
    <tr><td>Vector search</td><td>${data.vector_search_step}</td></tr>
  `;
  if (data.similarity !== null) {
    rows += `<tr><td>Similarity</td><td>${data.similarity.toFixed(4)}</td></tr>`;
  }
  rows += `<tr><td>Response time</td><td>${data.elapsed_ms} ms</td></tr>`;

  el.innerHTML = `
    <p><span class="badge ${data.cache_path}">${data.cache_path}</span></p>
    <pre>${data.response}</pre>
    <table>${rows}</table>
  `;
}

document.getElementById('query').addEventListener('keydown', e => {
  if (e.key === 'Enter') ask();
});
</script>
</body>
</html>
"""


def format_review_rows(rows):
    return "\n".join(" | ".join(str(col) for col in row) for row in rows)


@app.route("/")
def index():
    return render_template_string(PAGE)


@app.route("/ask", methods=["POST"])
def ask():
    body = request.get_json(silent=True) or {}
    query = (body.get("query") or "").strip()
    if not query:
        return jsonify({"error": "Empty question."}), 400

    start = time.monotonic()

    # ---- L1 ----
    exact_result = l1.get(query)
    if exact_result:
        elapsed_ms = int((time.monotonic() - start) * 1000)
        return jsonify({
            "cache_path": "L1",
            "response": exact_result,
            "process": "Served directly from Redis",
            "embedding_step": "Skipped",
            "vector_search_step": "Skipped",
            "similarity": None,
            "elapsed_ms": elapsed_ms,
        })

    # ---- Embedding (shared by the L2 lookup and, on a miss, the review search) ----
    try:
        embedding = generate_embedding(openai_client, query)
    except Exception as exc:
        return jsonify({"error": f"Failed to generate embedding: {exc}"}), 500

    # ---- L2 ----
    cache_id, similarity, response_text = l2.lookup(embedding)
    if cache_id is not None and l2.is_hit(similarity):
        l1.set(query, response_text)
        elapsed_ms = int((time.monotonic() - start) * 1000)
        return jsonify({
            "cache_path": "L2",
            "response": response_text,
            "process": "Generated embedding, found similar cached query",
            "embedding_step": "Executed",
            "vector_search_step": "Skipped main product review vector search",
            "similarity": similarity,
            "elapsed_ms": elapsed_ms,
        })

    # ---- Miss: real vector search ----
    rows = l2.search_reviews(embedding)
    fresh_result = format_review_rows(rows)

    l1.set(query, fresh_result)
    l2.insert(query, fresh_result, embedding)

    elapsed_ms = int((time.monotonic() - start) * 1000)
    return jsonify({
        "cache_path": "MISS",
        "response": fresh_result,
        "process": "Recomputed embedding and ran PostgreSQL vector search",
        "embedding_step": "Executed",
        "vector_search_step": "Executed against product review embeddings",
        "similarity": None,
        "elapsed_ms": elapsed_ms,
    })


@app.route("/flush", methods=["POST"])
def flush():
    l1.flush()
    l2.flush()
    return jsonify({"status": "cleared"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)
