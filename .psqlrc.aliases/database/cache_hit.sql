-- name: cachehit
-- desc: calculates your cache hit rate (effective databases are at 99% and up)

SELECT
    'index hit rate'                                                  AS name,
    (sum(idx_blks_hit)) / nullif(sum(idx_blks_hit + idx_blks_read),0) AS ratio

FROM
    pg_statio_user_indexes

    UNION ALL

SELECT
    'table hit rate'                                                        AS name,
    sum(heap_blks_hit) / nullif(sum(heap_blks_hit) + sum(heap_blks_read),0) AS ratio
FROM
    pg_statio_user_tables;

