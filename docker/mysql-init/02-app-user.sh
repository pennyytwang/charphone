#!/bin/bash
# 本機開發用：建立應用程式讀寫帳號，避免 web 容器直接使用 root。
set -e

: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD is required}"
APP_USER="${DB_USER:?DB_USER is required}"
APP_PASS="${DB_PASS:?DB_PASS is required}"

case "$APP_USER" in
  *[!A-Za-z0-9_]*|'') echo "invalid DB_USER" >&2; exit 1 ;;
esac

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<-EOSQL
CREATE USER IF NOT EXISTS '${APP_USER}'@'%' IDENTIFIED BY '${APP_PASS}';
ALTER USER '${APP_USER}'@'%' IDENTIFIED BY '${APP_PASS}';
GRANT ALL PRIVILEGES ON mydb.* TO '${APP_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL
