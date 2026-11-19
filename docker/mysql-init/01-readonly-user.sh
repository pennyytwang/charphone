#!/bin/bash
# 本機開發用：建立唯讀帳號，供 BaseDao 的 DB_RO pool 使用。
# 正式環境請依 AGENTS.md 的維運步驟，用 root 手動建立 charphone_ro。
set -e

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
RO_USER="${DB_RO_USER:?DB_RO_USER is required}"
RO_PASS="${DB_RO_PASS:?DB_RO_PASS is required}"

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
CREATE USER IF NOT EXISTS '${RO_USER}'@'%' IDENTIFIED BY '${RO_PASS}';
GRANT SELECT ON mydb.* TO '${RO_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL
