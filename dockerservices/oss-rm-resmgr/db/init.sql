SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';

-- schema owner
--CREATE ROLE resource_manager WITH password '1';

-- create schema
CREATE SCHEMA resource_manager AUTHORIZATION resource_manager;

--GRANT ALL PRIVILEGES ON DATABASE resource_manager TO resource_manager;

ALTER ROLE resource_manager WITH LOGIN;
