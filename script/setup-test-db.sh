#!/usr/bin/env bash

# By providing 'PG_USER' and ('PG_PASS' or `PG_ASK_PASS`) you can
# control how this script will authenticate to local pg server.
PARAMS="-U ${PG_USER:-postgres}"
[[ -z "$PG_PASS" ]] || PGPASSWORD="$PG_PASS"
[[ -z "$PG_ASK_PASS" ]] || PARAMS="$PARAMS -W"

psql $PARAMS -c "create database crystal_pg_test"
psql $PARAMS -c "create user crystal_pg with superuser password 'crystal_pg'"

psql $PARAMS crystal_pg_test -c "drop table if exists people; create table people( id serial primary key, last_name varchar(50), first_name varchar(50), number_of_dependents int, special_tax_group bool )"
psql $PARAMS crystal_pg_test -c "drop table if exists something_else; create table something_else( id serial primary key, name varchar(50) )"
psql $PARAMS crystal_pg_test -c "drop table if exists posts; create table posts( id serial primary key, title varchar(50), content text, created_at timestamp )"
