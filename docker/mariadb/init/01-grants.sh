#!/bin/bash
# The mariadb image only auto-creates/grants a single database from
# MARIADB_DATABASE, but Rails also needs an `app_test` database for the test
# environment (see backend/config/database.yml). Grant that database to
# whichever user MARIADB_USER resolves to, so overriding DB_USERNAME in
# docker/.env doesn't leave the app account locked out of app_test.
set -euo pipefail

mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}" <<-SQL
	CREATE DATABASE IF NOT EXISTS \`app_test\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
	GRANT ALL PRIVILEGES ON \`app_test\`.* TO '${MARIADB_USER}'@'%';
	FLUSH PRIVILEGES;
SQL
