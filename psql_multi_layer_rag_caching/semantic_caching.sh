###############################################################################
# CACHE INFRASTRUCTURE
###############################################################################

# Create semantic cache table for storing questions, responses, and embeddings
# Create HNSW index to accelerate semantic similarity searches

###############################################################################
# USER INTERACTION
###############################################################################

# Start interactive conversation loop
# Accept user questions until exit command is entered

###############################################################################
# QUERY PROCESSING
###############################################################################

# Normalize user queries for consistent cache matching
# Track query size and response time metrics

###############################################################################
# L1 EXACT CACHE (REDIS)
###############################################################################

# Check Redis exact-match cache
# Return cached result immediately on exact match
# Store fresh results in Redis cache
# Promote semantic cache hits into Redis cache

###############################################################################
# EMBEDDING OPERATIONS
###############################################################################

# Generate vector embedding for the user query
# Reuse embedding throughout the request lifecycle

###############################################################################
# L2 SEMANTIC CACHE (POSTGRESQL + PGVECTOR)
###############################################################################

# Search semantic cache for similar previously answered questions
# Calculate semantic similarity score
# Validate similarity against configured threshold
# Return cached semantic result when similarity is high enough

###############################################################################
# VECTOR SEARCH ENGINE
###############################################################################

# Execute product review vector search on cache miss
# Retrieve top matching reviews using vector similarity

###############################################################################
# CACHE PERSISTENCE
###############################################################################

# Store query, response, and embedding in semantic cache
# Build future semantic retrieval opportunities

###############################################################################
# OBSERVABILITY & PERFORMANCE
###############################################################################

# Display cache path used during execution
# Display timing, token estimates, and processing metrics

###############################################################################
# CACHE MAINTENANCE
###############################################################################

# Flush Redis exact-match cache entries
# Clear semantic cache records and reset identities

###############################################################################
# REQUEST FLOW
###############################################################################

# User Query
#   -> L1 Redis Exact Cache
#   -> L2 Semantic Cache
#   -> Product Review Vector Search
#   -> Save Results to Caches
#   -> Return Response
###############################################################################

# Demo
###############################################################################
# STEP 19
# SEMANTIC CACHE LOOP
###############################################################################

SEMANTIC_THRESHOLD=0.95

echo ""
echo "==============================================================="
echo "SEMANTIC CACHE CONFIGURATION"
echo "==============================================================="


###############################################################################
# CACHE TABLE / SEMANTIC CACHE STORAGE
###############################################################################
# Create semantic cache table to persist questions, responses, and embeddings
# Enable reuse of previously generated results for similar future queries
# Reduce repeated vector searches and embedding-related processing costs
# Support semantic similarity matching across different phrasings of the same question

psql \
  -h "$PG_HOST" \
  -U "$PG_ADMIN_USER" \
  -d "$DB_NAME" <<EOF

CREATE TABLE IF NOT EXISTS semantic_cache
(
    cache_id BIGSERIAL PRIMARY KEY,

    query_text TEXT NOT NULL,

    response_text TEXT NOT NULL,

    query_embedding VECTOR($EMBED_DIM),

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS semantic_cache_embedding_idx
ON semantic_cache
USING hnsw (query_embedding vector_cosine_ops);

EOF

echo "Semantic cache table ready."

###############################################################################
# CONVERSATION LOOP
###############################################################################

#!/usr/bin/env bash
set -u

###############################################################################
# REQUIRED ENVIRONMENT VARIABLES
# Fails fast with a clear message instead of a mid-loop python traceback.
###############################################################################

: "${SEMANTIC_THRESHOLD:=0.85}"   # default similarity cutoff if unset/empty
: "${CACHE_TTL_SECONDS:=3600}"    # default TTL if unset/empty

: "${REDIS_HOST:?REDIS_HOST is not set}"
: "${REDIS_PORT:?REDIS_PORT is not set}"
: "${REDIS_KEY:?REDIS_KEY is not set}"
: "${PG_HOST:?PG_HOST is not set}"
: "${PG_ADMIN_USER:?PG_ADMIN_USER is not set}"
: "${DB_NAME:?DB_NAME is not set}"
: "${OPENAI_EMBED_DEPLOYMENT:?OPENAI_EMBED_DEPLOYMENT is not set}"

while true
do

    echo ""
    read -r -p "Ask a question (or 'done'): " USER_QUERY

    ###########################################################################
    # EXIT
    ###########################################################################

    if [ "$(echo "$USER_QUERY" | tr '[:upper:]' '[:lower:]')" = "done" ]
    then
        echo "Goodbye."
        break
    fi

    START_MS=$(date +%s%3N)

    ###########################################################################
    # PERFORMANCE METADATA
    ###########################################################################

    QUERY_WORDS=$(echo "$USER_QUERY" | wc -w | xargs)

    TOKEN_ESTIMATE=$(QUERY_WORDS="$QUERY_WORDS" python3 <<'EOF'
import os
words = int(os.environ.get("QUERY_WORDS") or 0)
print(max(1, round(words * 1.5)))
EOF
)

    ###########################################################################
    # NORMALIZE
    ###########################################################################

    NORMALIZED_QUERY=$(echo "$USER_QUERY" \
        | tr '[:upper:]' '[:lower:]' \
        | sed 's/[[:punct:]]//g' \
        | xargs)

    EXACT_CACHE_KEY="exactcache:$(echo -n "$NORMALIZED_QUERY" | md5sum | cut -d' ' -f1)"

    ###########################################################################
    # L1 EXACT REDIS CACHE
    ###########################################################################

    EXACT_RESULT=$(redis-cli \
        -h "$REDIS_HOST" \
        -p "$REDIS_PORT" \
        --tls \
        -a "$REDIS_KEY" \
        --no-auth-warning \
        GET "$EXACT_CACHE_KEY")

    if [ -n "$EXACT_RESULT" ]
    then

        END_MS=$(date +%s%3N)

        echo ""
        echo "================================================="
        echo "L1 EXACT CACHE HIT"
        echo "================================================="
        echo "$EXACT_RESULT"

        echo ""
        echo "-------------------------------------------------"
        echo "PERFORMANCE DETAILS"
        echo "-------------------------------------------------"
        echo "Cache path    : L1 Redis exact cache HIT"
        echo "Process       : Served directly from Redis"
        echo "Embedding     : Skipped"
        echo "Vector search : Skipped"
        echo "Tokens used   : 0"
        echo "Query size    : $QUERY_WORDS words (~$TOKEN_ESTIMATE tokens est., not billed)"
        echo "Response time : $((END_MS-START_MS)) ms"
        echo "-------------------------------------------------"

        continue

    fi

    ###########################################################################
    # CREATE EMBEDDING ONCE
    ###########################################################################

    echo ""
    echo "Generating embedding..."

    QUERY_VECTOR=$(psql \
        -h "$PG_HOST" \
        -U "$PG_ADMIN_USER" \
        -d "$DB_NAME" \
        -t -A \
        -v deployment="$OPENAI_EMBED_DEPLOYMENT" \
        -v user_query="$USER_QUERY" <<'SQL'
SELECT replace(
    replace(
        azure_openai.create_embeddings(
            :'deployment',
            :'user_query'
        )::text,
        '{',
        '['
    ),
    '}',
    ']'
);
SQL
)

    if [ -z "$QUERY_VECTOR" ]
    then
        echo ""
        echo "ERROR: Failed to generate embedding."
        echo ""
        continue
    fi

    ###########################################################################
    # L2 SEMANTIC CACHE LOOKUP
    ###########################################################################

    CACHE_LOOKUP=$(psql \
        -h "$PG_HOST" \
        -U "$PG_ADMIN_USER" \
        -d "$DB_NAME" \
        -t -A \
        -F '|' \
        -v query_vector="$QUERY_VECTOR" <<'SQL'
SELECT
    cache_id,
    1 - (
        query_embedding <=>
        :'query_vector'::vector
    ) AS similarity
FROM semantic_cache
ORDER BY
    query_embedding <=>
    :'query_vector'::vector
LIMIT 1;
SQL
)

    CACHE_ID=$(echo "$CACHE_LOOKUP" | awk -F'|' '{print $1}')
    CACHE_SIMILARITY=$(echo "$CACHE_LOOKUP" | awk -F'|' '{print $2}')

    if [ -z "$CACHE_SIMILARITY" ]
    then
        CACHE_SIMILARITY=0
    fi

    # Pass values through the environment (not interpolated into python
    # source) so malformed/empty values can't corrupt the script, and so a
    # missing/empty SEMANTIC_THRESHOLD can't crash the comparison.
    SEMANTIC_HIT=$(CACHE_SIMILARITY="$CACHE_SIMILARITY" SEMANTIC_THRESHOLD="$SEMANTIC_THRESHOLD" python3 <<'EOF'
import os

def to_float(name, default):
    raw = os.environ.get(name, "")
    try:
        return float(raw)
    except (TypeError, ValueError):
        return default

s = to_float("CACHE_SIMILARITY", 0.0)
t = to_float("SEMANTIC_THRESHOLD", 0.85)
print("true" if s >= t else "false")
EOF
)

    ###########################################################################
    # L2 SEMANTIC CACHE HIT
    ###########################################################################

    if [ "$SEMANTIC_HIT" = "true" ]
    then

        RESPONSE_TEXT=$(psql \
            -h "$PG_HOST" \
            -U "$PG_ADMIN_USER" \
            -d "$DB_NAME" \
            -t -A \
            -v cache_id="$CACHE_ID" <<'SQL'
SELECT response_text
FROM semantic_cache
WHERE cache_id = :'cache_id';
SQL
)

        redis-cli \
            -h "$REDIS_HOST" \
            -p "$REDIS_PORT" \
            --tls \
            -a "$REDIS_KEY" \
            --no-auth-warning \
            SET "$EXACT_CACHE_KEY" "$RESPONSE_TEXT" EX "$CACHE_TTL_SECONDS" \
            > /dev/null

        END_MS=$(date +%s%3N)

        echo ""
        echo "================================================="
        echo "L2 SEMANTIC CACHE HIT"
        echo "================================================="
        echo "Similarity: $CACHE_SIMILARITY"
        echo ""
        echo "$RESPONSE_TEXT"

        echo ""
        echo "-------------------------------------------------"
        echo "PERFORMANCE DETAILS"
        echo "-------------------------------------------------"
        echo "Cache path    : L2 PostgreSQL semantic cache HIT"
        echo "Process       : Generated embedding, found similar cached query"
        echo "Embedding     : Executed"
        echo "Vector search : Skipped main product review vector search"
        echo "Redis update  : Promoted semantic result into Redis exact cache"
        echo "Tokens used   : ~$TOKEN_ESTIMATE tokens est. for embedding"
        echo "Query size    : $QUERY_WORDS words (~$TOKEN_ESTIMATE tokens est., embedding call was billed)"
        echo "Similarity    : $CACHE_SIMILARITY"
        echo "Response time : $((END_MS-START_MS)) ms"
        echo "-------------------------------------------------"

        continue

    fi

    ###########################################################################
    # CACHE MISS
    ###########################################################################

    echo ""
    echo "================================================="
    echo "CACHE MISS"
    echo "================================================="

    FRESH_RESULT=$(psql \
      -h "$PG_HOST" \
      -U "$PG_ADMIN_USER" \
      -d "$DB_NAME" \
      -t -A \
      -v query_vector="$QUERY_VECTOR" <<'SQL'
SELECT
    r.review_id || ' | ' ||
    r.product_id || ' | ' ||
    r.review_text || ' | ' ||
    r.sentiment_label
FROM product_reviews r
JOIN review_embeddings e
      ON r.review_id = e.review_id
ORDER BY
    e.embedding <=>
    :'query_vector'::vector
LIMIT 5;
SQL
)

    echo "$FRESH_RESULT"

    ###########################################################################
    # SAVE EXACT CACHE
    ###########################################################################

    redis-cli \
        -h "$REDIS_HOST" \
        -p "$REDIS_PORT" \
        --tls \
        -a "$REDIS_KEY" \
        --no-auth-warning \
        SET "$EXACT_CACHE_KEY" "$FRESH_RESULT" EX "$CACHE_TTL_SECONDS" \
        > /dev/null

    ###########################################################################
    # SAVE SEMANTIC CACHE
    ###########################################################################

    psql \
        -h "$PG_HOST" \
        -U "$PG_ADMIN_USER" \
        -d "$DB_NAME" \
        -v user_query="$USER_QUERY" \
        -v response_text="$FRESH_RESULT" \
        -v query_vector="$QUERY_VECTOR" <<'SQL' > /dev/null
INSERT INTO semantic_cache
(
    query_text,
    response_text,
    query_embedding
)
VALUES
(
    :'user_query',
    :'response_text',
    :'query_vector'::vector
);
SQL

    END_MS=$(date +%s%3N)

    echo ""
    echo "Stored in semantic cache."

    echo ""
    echo "-------------------------------------------------"
    echo "PERFORMANCE DETAILS"
    echo "-------------------------------------------------"
    echo "Cache path    : MISS"
    echo "Process       : Recomputed embedding and ran PostgreSQL vector search"
    echo "Embedding     : Executed"
    echo "Vector search : Executed against product review embeddings"
    echo "Redis update  : Saved result into Redis exact cache"
    echo "Semantic save : Saved query, response, and embedding into semantic_cache"
    echo "Tokens used   : ~$TOKEN_ESTIMATE tokens est. for embedding"
    echo "Query size    : $QUERY_WORDS words (~$TOKEN_ESTIMATE tokens est., embedding call was billed)"
    echo "Response time : $((END_MS-START_MS)) ms"
    echo "-------------------------------------------------"
    echo ""

done

###############################################################################
# EXAMPLES
###############################################################################
# good for video calls

# works really well for video calls

# webcam performs nicely in meetings

# excellent camera for teams meetings

# great webcam quality for zoom

# all should start converging toward a semantic cache hit

###############################################################################

# Delete all Redis cache data
redis-cli \
  -h "$REDIS_HOST" \
  -p "$REDIS_PORT" \
  --tls \
  -a "$REDIS_KEY" \
  --no-auth-warning \
  FLUSHDB

# Delete PostgreSQL semantic cache
psql \
  -h "$PG_HOST" \
  -U "$PG_ADMIN_USER" \
  -d "$DB_NAME" \
  -c "TRUNCATE TABLE semantic_cache RESTART IDENTITY;"