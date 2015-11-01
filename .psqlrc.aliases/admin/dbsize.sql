SELECT
   datname,
   PG_SIZE_PRETTY(PG_DATABASE_SIZE(datname)) AS db_size

FROM
   pg_database

ORDER BY
   PG_DATABASE_SIZE(datname) DESC;
