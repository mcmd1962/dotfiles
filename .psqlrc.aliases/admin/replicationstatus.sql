SELECT
   client_addr,
   backend_start,
   state,
   sent_location,
   write_location,
   flush_location,
   replay_location,
   PG_XLOG_LOCATION_DIFF(sent_location, replay_location)  AS  replay_delta

FROM
   pg_stat_replication;

