begin;

-- remove the supabase_realtime publication
drop
  publication if exists supabase_realtime;

-- re-create the supabase_realtime publication with no tables
create publication supabase_realtime;

commit;

alter
  publication supabase_realtime add table public.backend_messages;
alter
  publication supabase_realtime add table public.frontend_messages;
alter
  publication supabase_realtime add table public.users_data;