#!/bin/sh

until pg_isready -h $POSTGRES_HOST -p $PGPORT -U $POSTGRES_USER; do
  echo "Waiting for PostgreSQL to be ready..."
  sleep 2
done

echo "PostgreSQL is ready"

echo "Running migrations..."
/app/bin/mai eval "Mai.Release.migrate"
