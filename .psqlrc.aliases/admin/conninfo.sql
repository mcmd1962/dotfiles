SELECT
   usename,
   count(*)

FROM
   pg_stat_activity

GROUP BY
   usename;
