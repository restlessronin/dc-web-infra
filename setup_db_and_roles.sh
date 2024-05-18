#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <superuser> <superuser_password> <app_prefix> <database> <webapp_user_password> <webapp_readonly_password>"
    exit 1
fi

# Assign arguments to variables
SUPERUSER=$1
SUPERUSER_PASSWORD=$2
APP_PREFIX=$3
DATABASE=$4
WEBAPP_USER_PASSWORD=$5
WEBAPP_READONLY_PASSWORD=$6

# Combine app prefix with database name
FULL_DATABASE_NAME="${APP_PREFIX}_${DATABASE}"

# Create the database
PGPASSWORD=$SUPERUSER_PASSWORD psql -U $SUPERUSER -c "CREATE DATABASE $FULL_DATABASE_NAME;"

# Check for errors
if [ $? -ne 0 ]; then
    echo "An error occurred while creating the database."
    exit 1
fi

# Create roles and grant permissions
PGPASSWORD=$SUPERUSER_PASSWORD psql -d $FULL_DATABASE_NAME -U $SUPERUSER -c "
DO \$\$
DECLARE
    webapp_user_password TEXT := '$WEBAPP_USER_PASSWORD';
    webapp_readonly_password TEXT := '$WEBAPP_READONLY_PASSWORD';
    webapp_user_role TEXT := '${APP_PREFIX}_webapp_user';
    webapp_readonly_role TEXT := '${APP_PREFIX}_webapp_readonly';
BEGIN
    -- Create roles with login privileges
    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', webapp_user_role, webapp_user_password);
    EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', webapp_readonly_role, webapp_readonly_password);

    -- Grant permissions
    EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I, %I', current_database(), webapp_user_role, webapp_readonly_role);
    EXECUTE format('GRANT USAGE ON SCHEMA public TO %I, %I', webapp_user_role, webapp_readonly_role);
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO %I', webapp_user_role);
    EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA public TO %I', webapp_readonly_role);

    -- Optionally, restrict new tables
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO %I', webapp_readonly_role);
    EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO %I', webapp_user_role);
END \$\$;
"

# Check for errors
if [ $? -eq 0 ]; then
    echo "Database and roles created successfully."
else
    echo "An error occurred while creating roles and permissions."
    exit 1
fi
