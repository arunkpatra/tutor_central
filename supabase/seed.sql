-- Local development only: a tutor (meera@example.com, password tutor-local-1), her centre, two classes,
-- ten students, this month's fees with six paid, four weeks of attendance, two tasks.
-- The seed runs as the superuser, where auth.uid() is null, so it inserts rows directly instead of calling functions.

insert into auth.users (id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
                        confirmation_token, recovery_token, email_change_token_new, email_change,
                        raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
values ('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
        'meera@example.com', extensions.crypt('tutor-local-1', extensions.gen_salt('bf')), now(), '', '', '', '',
        '{"provider":"email","providers":["email"]}', '{}', now(), now());
insert into auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
values (gen_random_uuid(), '11111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111',
        '{"sub":"11111111-1111-1111-1111-111111111111","email":"meera@example.com","email_verified":true}',
        'email', now(), now(), now());

insert into public.centres (id, owner_id, name, upi_id, whatsapp_number)
values ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111',
        'Bright Minds Tuition', 'meera@okhdfcbank', '+919611299988');
insert into public.centre_members (centre_id, user_id, role)
values ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'owner');
insert into public.profiles (user_id, display_name) values ('11111111-1111-1111-1111-111111111111', 'Meera Nair');

insert into public.classes (id, centre_id, name, subject, monthly_fee, meeting_days, start_time, end_time) values
  ('33333333-3333-3333-3333-333333333331', '22222222-2222-2222-2222-222222222222',
   'Class 10 Maths', 'Mathematics', 1200, '{1,3,5}', '17:00', '18:00'),
  ('33333333-3333-3333-3333-333333333332', '22222222-2222-2222-2222-222222222222',
   'Class 8 Science', 'Science', 1000, '{2,4}', '16:30', '17:30');

insert into public.students (centre_id, class_id, name, monthly_fee, parent_name, parent_phone) values
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Akshita Rao', null, 'Priya Rao', '+919799113211'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Ananya Iyer', null, 'Suresh Iyer', '+917903092566'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Bir Bikram Singh', null, 'Harjeet Singh', '+917899487677'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333332', 'Dev Kumar', 1000, 'Ramesh Kumar', '+919884843831'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Hemanth Reddy', null, 'Lakshmi Reddy', '+919380260871'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Lakshmi Menon', null, 'Anil Menon', '+919972873953'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333332', 'Meher Shah', null, 'Kavita Shah', '+919176590665'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333332', 'Nikhil Das', null, 'Arup Das', '+919830012345'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333331', 'Riya Sharma', 1500, 'Neha Sharma', '+919811122233'),
  ('22222222-2222-2222-2222-222222222222', null, 'Sahil Verma', 800, 'Deepak Verma', '+919900011122');

-- V2 (Phase 11): one school and class levels for eight of the ten; Bir Bikram Singh and Lakshmi Menon stay as V1 made
-- them, so a hand run always meets a student with no class level.
insert into public.schools (id, centre_id, name, board) values
  ('44444444-4444-4444-4444-444444444441', '22222222-2222-2222-2222-222222222222', 'Vidya Niketan', 'cbse');
update public.students set class_level = '10', school_id = '44444444-4444-4444-4444-444444444441', board = 'cbse'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name in ('Hemanth Reddy', 'Akshita Rao', 'Ananya Iyer');
update public.students set class_level = '8' where centre_id = '22222222-2222-2222-2222-222222222222'
   and name in ('Dev Kumar', 'Meher Shah', 'Nikhil Das');
update public.students set class_level = '5', school_id = '44444444-4444-4444-4444-444444444441'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Riya Sharma';
update public.students set class_level = '2' where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Sahil Verma';

-- This month's fees for everyone (what generate_fees would make), then six of them paid.
insert into public.fee_invoices (centre_id, student_id, period, amount)
select s.centre_id, s.id, date_trunc('month', current_date)::date, coalesce(s.monthly_fee, c.monthly_fee, 0)
from public.students s left join public.classes c on c.id = s.class_id
where s.centre_id = '22222222-2222-2222-2222-222222222222';
update public.fee_invoices f set status = 'paid', paid_at = now() - interval '3 days', paid_method = 'upi'
from public.students s
where s.id = f.student_id
  and s.name in ('Akshita Rao', 'Ananya Iyer', 'Bir Bikram Singh', 'Lakshmi Menon', 'Meher Shah', 'Riya Sharma');

-- The last four weeks of attendance on each class's meeting days (ISO weekday 1 = Monday); every fifth mark absent.
insert into public.attendance_sessions (centre_id, class_id, date)
select c.centre_id, c.id, d::date
from public.classes c, generate_series(current_date - 27, current_date - 1, interval '1 day') d
where c.centre_id = '22222222-2222-2222-2222-222222222222' and extract(isodow from d)::smallint = any (c.meeting_days);
insert into public.attendance_marks (centre_id, session_id, student_id, status)
select a.centre_id, a.id, s.id,
       case when row_number() over (order by a.date, s.name) % 5 = 0 then 'absent' else 'present' end::public.attendance_status
from public.attendance_sessions a join public.students s on s.class_id = a.class_id;

insert into public.tasks (centre_id, title, due_date) values
  ('22222222-2222-2222-2222-222222222222', 'Buy chalk and dusters', null),
  ('22222222-2222-2222-2222-222222222222', 'Call Dev''s father about Saturday', current_date + 2);
