-- The mariadb image only auto-creates/grants a single database from
-- MARIADB_DATABASE, but Rails also needs an `app_test` database for the
-- test environment. Grant the app user access to every `app_*` database.
CREATE DATABASE IF NOT EXISTS `app_test` CHARACTER SET utf8mb4;
GRANT ALL PRIVILEGES ON `app_%`.* TO 'app'@'%';
FLUSH PRIVILEGES;
