CREATE DATABASE appdb;

CREATE ROLE app_readonly NOLOGIN;

GRANT CONNECT ON DATABASE appdb TO app_readonly;

\connect appdb

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL
);

INSERT INTO customers (name, email)
VALUES
    ('Alice', 'alice@example.com'),
    ('Bob', 'bob@example.com');

GRANT USAGE ON SCHEMA public TO app_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

ALTER DEFAULT PRIVILEGES
    IN SCHEMA public
    GRANT SELECT ON TABLES TO app_readonly;

CREATE ROLE vaultadmin
    LOGIN
    PASSWORD 'VaultDB_Admin_ChangeMe_2026'
    CREATEROLE;

GRANT CONNECT ON DATABASE appdb TO vaultadmin;

GRANT app_readonly
    TO vaultadmin
    WITH ADMIN OPTION;
