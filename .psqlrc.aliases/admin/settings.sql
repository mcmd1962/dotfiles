SELECT
   LEFT(category, 80)  AS category,
   name,
   setting,
   coalesce(unit, '-') AS unit,
   context

FROM pg_settings

WHERE
   category NOT IN ( 'Version and Platform Compatibility / Previous PostgreSQL Versions', 'Version and Platform Compatibility / Other Platforms and Clients')

ORDER BY category,name;
