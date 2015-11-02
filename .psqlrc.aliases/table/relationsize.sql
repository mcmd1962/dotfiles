SELECT
   nspname || '.' || relname AS "relation",
   PG_SIZE_PRETTY(PG_RELATION_SIZE(C.oid)) AS "size"

FROM
   pg_class C
   LEFT JOIN pg_namespace N ON (N.oid = C.relnamespace)

WHERE
   nspname NOT IN ('pg_catalog', 'information_schema')

ORDER BY
   pg_relation_size(C.oid) DESC LIMIT 40;

