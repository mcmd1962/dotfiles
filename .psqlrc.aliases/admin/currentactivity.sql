SELECT
   datname,
   usename,
   application_name AS "client",
   query

FROM
   pg_stat_activity

WHERE
   state != 'idle';
