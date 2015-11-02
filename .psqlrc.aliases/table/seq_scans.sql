-- name: seqscans
-- desc: show the count of sequential scans by table descending by order

SELECT
    relname   AS name,
    seq_scan  AS count

FROM
    pg_stat_user_tables

ORDER BY
    seq_scan DESC;
