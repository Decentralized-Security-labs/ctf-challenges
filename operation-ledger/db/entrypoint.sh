#!/bin/bash
set -e

# Start SQL Server in the background, wait until it answers, seed the
# reporting database once, then hand control back to sqlservr in the
# foreground. The wallet key file was already written at build time.

SQLCMD=/opt/mssql-tools18/bin/sqlcmd

/opt/mssql/bin/sqlservr &
SQLSERVR_PID=$!

echo "[*] Waiting for SQL Server to accept connections..."
for i in $(seq 1 60); do
  if "$SQLCMD" -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -l 2 \
       -Q "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

if [ ! -f /var/opt/mssql/.seeded ]; then
  echo "[*] Seeding reporting database..."
  "$SQLCMD" -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -i /usr/src/init.sql
  touch /var/opt/mssql/.seeded
  echo "[+] Seed complete."
fi

wait "$SQLSERVR_PID"
