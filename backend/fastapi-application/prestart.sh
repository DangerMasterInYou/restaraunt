#!/usr/bin/env bash

set -e

echo "Run apply migration ..."
alembic upgrade head
echo "Migration applied!"


exec "$@"