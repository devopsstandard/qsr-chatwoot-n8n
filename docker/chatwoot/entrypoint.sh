#!/bin/sh
set -e

# Remove stale server pid file if present
if [ -f tmp/pids/server.pid ]; then
  rm -f tmp/pids/server.pid
fi

# Run pending database migrations if DB_PREPARE is set
if [ "${DB_PREPARE:-false}" = "true" ]; then
  echo "==> Running Rails database migrations..."
  bundle exec rails db:prepare
fi

exec "$@"
