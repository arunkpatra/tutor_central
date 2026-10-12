-- The rows of every public table there is, by name: run on production and on the restored copy by the restore drill
-- (.github/workflows/restore-drill.yml). One statement that reads the tables as they are on each side, so production
-- before a deploy's migrations is counted as it stands (supabase/tests/restore-count.test.ts).
select t.table_name as name,
       (xpath('/row/n/text()', query_to_xml(format('select count(*) as n from public.%I', t.table_name), false, true, '')))[1]::text::bigint as n
  from information_schema.tables t
 where t.table_schema = 'public' and t.table_type = 'BASE TABLE'
 order by t.table_name;
