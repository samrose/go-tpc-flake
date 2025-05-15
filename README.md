# go-tpc-flake

A Nix flake for running database benchmarks using go-tpc, supporting both TPC-C and raw SQL benchmarks.

## Prerequisites

- [Nix](https://nixos.org/download.html) installed on your system
- A PostgreSQL database to benchmark against

## Configuration

1. Copy the `.env` file and update it with your database connection details:

```bash
cp .env.example .env
```

2. Edit the `.env` file with your database configuration:

```env
POSTGRES_URL="postgres://user:password@host:5432/dbname"
WAREHOUSES=10      # For TPC-C benchmark
THREADS=8          # Number of concurrent threads
DURATION="300s"    # Test duration
SSL_MODE="disable" # SSL mode: "require", "verify-full", "verify-ca", or "disable"
```

## Usage

The tool supports two types of benchmarks:

### TPC-C Benchmark

Run the TPC-C benchmark:

```bash
nix run .# -- --warehouses
```

This will:
1. Prepare the database with the TPC-C schema
2. Load initial data based on the number of warehouses
3. Run the benchmark for the specified duration
4. Save results to the results file

### Raw SQL Benchmark

Run a benchmark with custom SQL queries:

```bash
nix run .# -- --rawsql "path/to/queries/*.sql"
```

The SQL file should contain the queries you want to benchmark. Example queries are provided in `queries/test.sql`.

## Development

Enter the development shell:

```bash
nix develop
```

This provides:
- Go development tools
- Shellcheck for script linting
- go-tpc command line tool

## License

MIT License - see [LICENSE](LICENSE) file for details. 