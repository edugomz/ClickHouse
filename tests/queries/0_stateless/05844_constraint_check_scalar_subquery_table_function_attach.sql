-- Tags: no-replicated-database
--       no-replicated-database: `DETACH DATABASE` / `ATTACH DATABASE`.

-- A `CHECK` constraint with a scalar subquery that reads a table function is accepted by `CREATE` and
-- `ALTER ADD CONSTRAINT`, which analyse it with the query context. Loading the table back from its stored
-- metadata (a server restart, here re-attaching the database) must not analyse it again: the loader has no
-- query context, a table function cannot be resolved without one, and a table that fails to load breaks
-- `system.tables` and cannot be dropped.

DROP DATABASE IF EXISTS {CLICKHOUSE_DATABASE_1:Identifier};
CREATE DATABASE {CLICKHOUSE_DATABASE_1:Identifier} ENGINE = Atomic;

CREATE TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_memory (x UInt8, CONSTRAINT c CHECK ((SELECT 1 FROM numbers(1)) = 1)) ENGINE = Memory;

CREATE TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_merge_tree (x UInt64) ENGINE = MergeTree ORDER BY x;
ALTER TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_merge_tree ADD CONSTRAINT c CHECK x < (SELECT count() FROM numbers(10));

-- A new definition is still analysed.
CREATE TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_bad (x UInt8, CONSTRAINT c CHECK x < (SELECT y FROM numbers(1))) ENGINE = Memory; -- { serverError UNKNOWN_IDENTIFIER }
ALTER TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_merge_tree ADD CONSTRAINT c2 CHECK x < (SELECT y FROM numbers(1)); -- { serverError UNKNOWN_IDENTIFIER }

DETACH DATABASE {CLICKHOUSE_DATABASE_1:Identifier};
ATTACH DATABASE {CLICKHOUSE_DATABASE_1:Identifier};

SELECT name, create_table_query LIKE '%CONSTRAINT c CHECK%numbers(%' FROM system.tables WHERE database = {CLICKHOUSE_DATABASE_1:String} ORDER BY name;
SELECT count() FROM {CLICKHOUSE_DATABASE_1:Identifier}.t_memory;
SELECT count() FROM {CLICKHOUSE_DATABASE_1:Identifier}.t_merge_tree;

DROP TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_memory;
DROP TABLE {CLICKHOUSE_DATABASE_1:Identifier}.t_merge_tree;
SELECT count() FROM system.tables WHERE database = {CLICKHOUSE_DATABASE_1:String};

DROP DATABASE {CLICKHOUSE_DATABASE_1:Identifier};
