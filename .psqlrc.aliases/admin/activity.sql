SELECT
   datname,
   pid,
   usename,
   application_name AS "client",
   client_addr,
   client_hostname,
   client_port,
   query,
   state

FROM
   pg_stat_activity;
