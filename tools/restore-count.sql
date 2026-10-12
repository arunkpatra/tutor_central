-- The rows of every public table, by name: run on production and on the restored copy by the restore drill
-- (.github/workflows/restore-drill.yml); tools/restore-count.test.ts holds it to supabase/types.ts.
select 'admin_audit' as name, count(*) as n from public.admin_audit
union all
select 'ai_generations' as name, count(*) as n from public.ai_generations
union all
select 'alerts' as name, count(*) as n from public.alerts
union all
select 'api_requests' as name, count(*) as n from public.api_requests
union all
select 'artefacts' as name, count(*) as n from public.artefacts
union all
select 'attendance_marks' as name, count(*) as n from public.attendance_marks
union all
select 'attendance_sessions' as name, count(*) as n from public.attendance_sessions
union all
select 'calendar_events' as name, count(*) as n from public.calendar_events
union all
select 'centre_members' as name, count(*) as n from public.centre_members
union all
select 'centres' as name, count(*) as n from public.centres
union all
select 'chapters' as name, count(*) as n from public.chapters
union all
select 'checks' as name, count(*) as n from public.checks
union all
select 'classes' as name, count(*) as n from public.classes
union all
select 'consent_events' as name, count(*) as n from public.consent_events
union all
select 'device_tokens' as name, count(*) as n from public.device_tokens
union all
select 'events' as name, count(*) as n from public.events
union all
select 'fee_invoices' as name, count(*) as n from public.fee_invoices
union all
select 'homework' as name, count(*) as n from public.homework
union all
select 'job_steps' as name, count(*) as n from public.job_steps
union all
select 'jobs' as name, count(*) as n from public.jobs
union all
select 'marks' as name, count(*) as n from public.marks
union all
select 'message_log' as name, count(*) as n from public.message_log
union all
select 'plan_items' as name, count(*) as n from public.plan_items
union all
select 'plans' as name, count(*) as n from public.plans
union all
select 'profiles' as name, count(*) as n from public.profiles
union all
select 'school_items' as name, count(*) as n from public.school_items
union all
select 'schools' as name, count(*) as n from public.schools
union all
select 'skills' as name, count(*) as n from public.skills
union all
select 'students' as name, count(*) as n from public.students
union all
select 'syllabi' as name, count(*) as n from public.syllabi
union all
select 'tasks' as name, count(*) as n from public.tasks
union all
select 'textbooks' as name, count(*) as n from public.textbooks
order by name;
