#!/usr/bin/env bash

# Load environment variables
set -a
source .env
set +a

echo "Starting script..."
echo "Environment variables loaded"

# Extract connection parameters from the URL
# Format: postgres://user:password@host:port/dbname
USER=$(echo "$POSTGRES_URL" | sed -n 's/postgres:\/\/\([^:]*\):.*/\1/p')
PASSWORD=$(echo "$POSTGRES_URL" | sed -n 's/postgres:\/\/[^:]*:\([^@]*\)@.*/\1/p')
HOST=$(echo "$POSTGRES_URL" | sed -n 's/postgres:\/\/[^@]*@\([^:]*\):.*/\1/p')
PORT=$(echo "$POSTGRES_URL" | sed -n 's/postgres:\/\/[^@]*@[^:]*:\([^\/]*\)\/.*/\1/p')
DBNAME=$(echo "$POSTGRES_URL" | sed -n 's/postgres:\/\/[^@]*@[^:]*:[^\/]*\/\(.*\)/\1/p')

echo "Connection parameters extracted:"
echo "Host: $HOST"
echo "Port: $PORT"
echo "Database: $DBNAME"
echo "User: $USER"

# Validate SSL mode
valid_ssl_modes=("require" "verify-full" "verify-ca" "disable")
if [[ ! " ${valid_ssl_modes[*]} " =~ " ${SSL_MODE} " ]]; then
    echo "Error: Invalid SSL mode '$SSL_MODE'. Must be one of: ${valid_ssl_modes[*]}"
    exit 1
fi

# Parse command line arguments
WAREHOUSES_FLAG=false
RAWSQL_FLAG=false
RAWSQL_PATH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --warehouses)
            WAREHOUSES_FLAG=true
            shift
            ;;
        --rawsql)
            RAWSQL_FLAG=true
            RAWSQL_PATH="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--warehouses | --rawsql <path>]"
            exit 1
            ;;
    esac
done

# Validate that exactly one flag is set
if [[ "$WAREHOUSES_FLAG" == "$RAWSQL_FLAG" ]]; then
    echo "Error: Must specify exactly one of --warehouses or --rawsql"
    echo "Usage: $0 [--warehouses | --rawsql <path>]"
    exit 1
fi

echo "Command line arguments parsed"
echo "Raw SQL path: $RAWSQL_PATH"

# Common database connection parameters
DB_PARAMS=(
    -d postgres
    -U "$USER"
    -p "$PASSWORD"
    -D "$DBNAME"
    -H "$HOST"
    -P "$PORT"
    --conn-params "sslmode=${SSL_MODE}&synchronous_commit=off&random_page_cost=1.1"
    -T "$THREADS"
    --time "$DURATION"
    --output "json"
)

if [[ "$WAREHOUSES_FLAG" == true ]]; then
    # Prepare the database for TPC-C
    echo "Preparing database for TPC-C benchmark..."
    go-tpc tpcc --warehouses "$WAREHOUSES" prepare "${DB_PARAMS[@]}"

    # Run TPC-C benchmark
    echo "Running TPC-C benchmark..."
    go-tpc tpcc --warehouses "$WAREHOUSES" run "${DB_PARAMS[@]}" > "$RESULTS_FILE"
else
    # Run raw SQL benchmark
    echo "Running raw SQL benchmark..."
    echo "Executing command: go-tpc rawsql run --query-files $RAWSQL_PATH ${DB_PARAMS[@]}"
    go-tpc rawsql run --query-files "$RAWSQL_PATH" "${DB_PARAMS[@]}" > "$RESULTS_FILE"
fi

echo "Script completed"
