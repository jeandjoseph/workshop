###############################################################################
# CLEAR ALL SEMANTIC AND EXACT CACHE
###############################################################################

echo ""
echo "==============================================================="
echo "CLEARING CACHE"
echo "==============================================================="

###############################################################################
# CLEAR POSTGRES SEMANTIC CACHE
###############################################################################

psql \
  -h "$PG_HOST" \
  -U "$PG_ADMIN_USER" \
  -d "$DB_NAME" \
  -c "TRUNCATE TABLE semantic_cache RESTART IDENTITY;"

echo "PostgreSQL semantic cache cleared."

###############################################################################
# CLEAR REDIS EXACT CACHE
###############################################################################

redis-cli \
  -h "$REDIS_HOST" \
  -p "$REDIS_PORT" \
  --tls \
  -a "$REDIS_KEY" \
  --no-auth-warning \
  --scan \
  --pattern "exactcache:*" \
| xargs -r -I {} redis-cli \
  -h "$REDIS_HOST" \
  -p "$REDIS_PORT" \
  --tls \
  -a "$REDIS_KEY" \
  --no-auth-warning \
  DEL "{}" > /dev/null

echo "Redis exact cache cleared."

echo ""
echo "All cache cleared."
echo ""