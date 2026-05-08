#!/usr/bin/env python3
"""Repair a Frappe site's MariaDB user to match site_config.json."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

import MySQLdb


def quote_string(value: str) -> str:
    return "'" + value.replace("\\", "\\\\").replace("'", "''") + "'"


def quote_identifier(value: str) -> str:
    return "`" + value.replace("`", "``") + "`"


def main() -> int:
    site = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("SITE_DOMAIN")
    if not site:
        print("Error: SITE_DOMAIN is required.", file=sys.stderr)
        return 1

    config_path = Path("/home/frappe/frappe-bench/sites") / site / "site_config.json"
    with config_path.open() as config_file:
        config = json.load(config_file)

    db_name = config.get("db_name")
    db_password = config.get("db_password")
    if not db_name or not db_password:
        print(f"Error: Missing db_name/db_password in {config_path}", file=sys.stderr)
        return 1

    root_password = (
        os.environ.get("MYSQL_ROOT_PASSWORD")
        or os.environ.get("MARIADB_ROOT_PASSWORD")
        or os.environ.get("DB_ROOT_PASSWORD")
    )
    if not root_password:
        print("Error: MYSQL_ROOT_PASSWORD or MARIADB_ROOT_PASSWORD is required.", file=sys.stderr)
        return 1

    host = config.get("db_host") or "db"
    connection = MySQLdb.connect(host=host, user="root", passwd=root_password)
    cursor = connection.cursor()

    user = quote_string(db_name)
    database = quote_identifier(db_name)
    password = quote_string(db_password)

    cursor.execute(f"CREATE USER IF NOT EXISTS {user}@'%' IDENTIFIED BY {password}")
    cursor.execute(f"ALTER USER {user}@'%' IDENTIFIED BY {password}")
    cursor.execute(f"GRANT ALL PRIVILEGES ON {database}.* TO {user}@'%'")
    cursor.execute("FLUSH PRIVILEGES")
    connection.commit()

    print(f"MariaDB credentials repaired for site database {db_name}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
