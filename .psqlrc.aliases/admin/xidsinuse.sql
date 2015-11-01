-- name: Autovac Freeze
-- desc: shows how many txn xids are in use

SELECT
   current_timestamp(0),
   freez, txns,
   ROUND(1000*(txns/freez::float)),
   datname

FROM
   (
      SELECT
         foo.freez::int,
         age(datfrozenxid) AS txns,
         datname

      FROM
         pg_database d
         JOIN (
                 SELECT
                    setting AS freez
                 FROM
                    pg_settings
                 WHERE
                    name = 'autovacuum_freeze_max_age') AS foo ON (true)
                 WHERE d.datallowconn
   ) AS foo2

ORDER BY 3 DESC, 4 ASC;

