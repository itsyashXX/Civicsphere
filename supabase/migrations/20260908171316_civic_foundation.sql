-- CivicSphere milestone 1. Apply only to a dedicated, approved Supabase project.
begin;
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
create schema if not exists civic_private;
revoke all on schema civic_private from public, anon;
grant usage on schema civic_private to authenticated;
create type public.civic_role as enum ('SUPER_ADMIN','ADMIN','CITY_OFFICER','DEPARTMENT_MANAGER','GIS_ANALYST','FIELD_OFFICER','REVIEWER','DATA_MANAGER','REPORT_ANALYST','VIEWER','PUBLIC_USER');
create type public.issue_severity as enum ('CRITICAL','HIGH','MEDIUM','LOW','INFO');
create type public.issue_status as enum ('DETECTED','PENDING_REVIEW','VERIFIED','ASSIGNED','ACCEPTED_BY_DEPARTMENT','IN_PROGRESS','FIELD_VERIFICATION_REQUIRED','FIELD_VERIFIED','RESOLUTION_PENDING_REVIEW','RESOLVED','REJECTED','DUPLICATE','REOPENED','CLOSED');
create type public.dataset_status as enum ('UPLOADED','VALIDATING','NEEDS_CRS','VALID','PROCESSING','READY','FAILED','ARCHIVED');
create table public.organizations(id uuid primary key default gen_random_uuid(),name text not null,city_name text not null,timezone text not null default 'Asia/Kolkata',created_at timestamptz not null default now());
create table public.departments(id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations,name text not null,code text not null,description text,email text,phone text,manager_id uuid,default_sla_policy jsonb not null default '{}'::jsonb,is_active boolean not null default true,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(organization_id,code),unique(id,organization_id));
create table public.profiles(id uuid primary key references auth.users on delete cascade,organization_id uuid not null references public.organizations,department_id uuid,username text,display_name text not null,first_name text,last_name text,avatar_url text,role public.civic_role not null default 'VIEWER',preferred_language text not null default 'en',timezone text not null default 'Asia/Kolkata',notification_preferences jsonb not null default '{}',is_active boolean not null default true,onboarding_completed boolean not null default false,last_active_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(id,organization_id),foreign key(department_id,organization_id) references public.departments(id,organization_id));
-- No user-controlled role metadata and no client write grants on profiles.
create table public.datasets(id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations,name text not null,description text,dataset_type text not null,source_authority text,storage_path text not null unique,file_size bigint not null check(file_size>0 and file_size<=524288000),file_extension text not null,mime_type text not null,checksum text,status public.dataset_status not null default 'UPLOADED',original_crs text,target_crs text not null default 'EPSG:4326',geometry_type text,feature_count bigint check(feature_count>=0),bounding_box extensions.geometry(Polygon,4326),metadata jsonb not null default '{}',uploaded_by uuid not null,uploaded_at timestamptz not null default now(),validated_at timestamptz,processed_at timestamptz,processing_error text,version int not null default 1 check(version>0),is_public boolean not null default false,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(id,organization_id),foreign key(uploaded_by,organization_id) references public.profiles(id,organization_id));
create table public.issues(id uuid primary key default gen_random_uuid(),issue_id text not null unique default ('CS-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,12))),organization_id uuid not null references public.organizations,title text not null check(length(title) between 5 and 180),description text not null check(length(description)<=10000),issue_type text not null,status public.issue_status not null default 'PENDING_REVIEW',severity public.issue_severity not null default 'MEDIUM',priority_score smallint not null default 0 check(priority_score between 0 and 100),confidence_score smallint not null default 0 check(confidence_score between 0 and 100),risk_score smallint not null default 0 check(risk_score between 0 and 100),geometry extensions.geometry(Point,4326) not null,latitude double precision generated always as (extensions.st_y(geometry)) stored,longitude double precision generated always as (extensions.st_x(geometry)) stored,address text,ward text,zone text,source text not null,source_dataset uuid,detected_at timestamptz,reported_at timestamptz,assigned_department uuid,assigned_officer uuid,created_by uuid not null,reviewed_by uuid,resolved_by uuid,resolved_at timestamptz,resolution_notes text,duplicate_of uuid,deadline timestamptz,metadata jsonb not null default '{}',created_at timestamptz not null default now(),updated_at timestamptz not null default now(),unique(id,organization_id),check(extensions.st_x(geometry) between -180 and 180 and extensions.st_y(geometry) between -90 and 90),foreign key(created_by,organization_id) references public.profiles(id,organization_id),foreign key(assigned_department,organization_id) references public.departments(id,organization_id),foreign key(assigned_officer,organization_id) references public.profiles(id,organization_id),foreign key(source_dataset,organization_id) references public.datasets(id,organization_id),foreign key(duplicate_of,organization_id) references public.issues(id,organization_id));
create table public.audit_logs(id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations,actor_user_id uuid not null,action text not null,object_type text not null,object_id uuid not null,previous_values jsonb,new_values jsonb,reason text,correlation_id uuid not null,created_at timestamptz not null default now(),unique(actor_user_id,correlation_id),foreign key(actor_user_id,organization_id) references public.profiles(id,organization_id));
create index issues_geometry_gist on public.issues using gist(geometry);
create index issues_org_status_date on public.issues(organization_id,status,created_at desc);
create index issues_org_severity on public.issues(organization_id,severity);
create index issues_department on public.issues(assigned_department);
create index issues_officer on public.issues(assigned_officer);
create index issues_priority on public.issues(organization_id,priority_score desc);
create index issues_type on public.issues(organization_id,issue_type);
create index issues_confidence on public.issues(confidence_score);
create index issues_risk on public.issues(risk_score);
create index issues_deadline on public.issues(deadline) where deadline is not null;
create index issues_dataset on public.issues(source_dataset);
create index datasets_org_status on public.datasets(organization_id,status);
create index profiles_department on public.profiles(department_id);
create index audit_object on public.audit_logs(organization_id,object_id,created_at);
alter table public.organizations enable row level security;
alter table public.departments enable row level security;
alter table public.profiles enable row level security;
alter table public.datasets enable row level security;
alter table public.issues enable row level security;
alter table public.audit_logs enable row level security;
-- Private definer lookup avoids recursive profile policies. A revoked session or
-- suspended profile loses access immediately, regardless of stale role claims.
create function civic_private.current_profile() returns public.profiles language sql stable security definer set search_path='' as $$
 select p from public.profiles p where auth.uid() is not null and p.id=auth.uid() and p.is_active and exists(select 1 from auth.sessions s where s.user_id=p.id and s.id::text=auth.jwt()->>'session_id')
$$;
revoke all on function civic_private.current_profile() from public,anon;
grant execute on function civic_private.current_profile() to authenticated;
create function civic_private.can_read_issue(org uuid,dept uuid,officer uuid,creator uuid) returns boolean language sql stable security invoker set search_path='' as $$
 select coalesce(p.organization_id=org and p.role<>'PUBLIC_USER' and (p.role in ('SUPER_ADMIN','ADMIN','CITY_OFFICER','GIS_ANALYST','REVIEWER','DATA_MANAGER','REPORT_ANALYST','VIEWER') or (p.role='DEPARTMENT_MANAGER' and p.department_id=dept) or (p.role='FIELD_OFFICER' and officer=p.id) or creator=p.id),false) from civic_private.current_profile() p
$$;
revoke all on function civic_private.can_read_issue(uuid,uuid,uuid,uuid) from public,anon;
grant execute on function civic_private.can_read_issue(uuid,uuid,uuid,uuid) to authenticated;
create policy organization_read on public.organizations for select to authenticated using(id=(select (civic_private.current_profile()).organization_id));
create policy departments_read on public.departments for select to authenticated using(organization_id=(select (civic_private.current_profile()).organization_id) and (select (civic_private.current_profile()).role)<>'PUBLIC_USER');
create policy profiles_read on public.profiles for select to authenticated using(organization_id=(select (civic_private.current_profile()).organization_id) and (id=auth.uid() or (select (civic_private.current_profile()).role) in ('ADMIN','SUPER_ADMIN')));
create policy datasets_read on public.datasets for select to authenticated using(organization_id=(select (civic_private.current_profile()).organization_id) and ((select (civic_private.current_profile()).role) in ('ADMIN','SUPER_ADMIN','CITY_OFFICER','GIS_ANALYST','DATA_MANAGER') or uploaded_by=auth.uid()));
create policy issues_read on public.issues for select to authenticated using(civic_private.can_read_issue(organization_id,assigned_department,assigned_officer,created_by));
create policy audit_read on public.audit_logs for select to authenticated using(organization_id=(select (civic_private.current_profile()).organization_id) and ((select (civic_private.current_profile()).role) in ('ADMIN','SUPER_ADMIN','CITY_OFFICER','REVIEWER') or actor_user_id=auth.uid()));
revoke all on public.organizations,public.departments,public.profiles,public.datasets,public.issues,public.audit_logs from anon,authenticated;
grant select on public.organizations,public.departments,public.profiles,public.datasets,public.issues,public.audit_logs to authenticated;
-- RLS remains active in read RPCs. Bounded result, validated geographic extent.
create function public.issues_in_view(west double precision,south double precision,east double precision,north double precision,severity_filter public.issue_severity default null) returns setof public.issues language plpgsql stable security invoker set search_path='' as $$
begin
 if west is null or south is null or east is null or north is null or not(west>=-180 and east<=180 and south>=-90 and north<=90 and west<east and south<north) then raise exception 'INVALID_BOUNDS' using errcode='22023'; end if;
 return query select i.* from public.issues i where i.geometry operator(extensions.&&) extensions.st_makeenvelope(west,south,east,north,4326) and (severity_filter is null or i.severity=severity_filter) order by i.priority_score desc,i.id limit 100;
end $$;
create function public.city_statistics() returns jsonb language sql stable security invoker set search_path='' as $$
 select jsonb_build_object('total',count(*),'open',count(*) filter(where status not in ('RESOLVED','CLOSED','REJECTED','DUPLICATE')),'critical',count(*) filter(where severity='CRITICAL' and status not in ('RESOLVED','CLOSED','REJECTED','DUPLICATE')),'resolved',count(*) filter(where status in ('RESOLVED','CLOSED')),'review',count(*) filter(where status='PENDING_REVIEW')) from public.issues
$$;
-- Only this authorized command can transition a review. The public wrapper uses
-- invoker rights; private implementation checks trusted identity and row scope.
create function civic_private.review_issue(target_id uuid,decision public.issue_status,review_reason text,request_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.profiles; prior public.issues; result public.issues; previous_request public.audit_logs;
begin
 if auth.uid() is null then raise exception 'AUTH_REQUIRED' using errcode='42501'; end if;
 select * into p from civic_private.current_profile();
 if p.id is null or p.role not in ('SUPER_ADMIN','ADMIN','CITY_OFFICER','REVIEWER') then raise exception 'FORBIDDEN' using errcode='42501'; end if;
 if request_id is null or decision not in ('VERIFIED','REJECTED') or decision is null or review_reason is null or length(trim(review_reason)) not between 10 and 2000 then raise exception 'INVALID_REVIEW' using errcode='22023'; end if;
 perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended(p.id::text||request_id::text,0));
 select * into previous_request from public.audit_logs a where a.actor_user_id=p.id and a.correlation_id=request_id;
 if found then
  if previous_request.object_id<>target_id or previous_request.new_values->>'status'<>decision::text or previous_request.reason<>review_reason then raise exception 'IDEMPOTENCY_CONFLICT' using errcode='22023'; end if;
  return jsonb_build_object('success',true,'data',previous_request.new_values);
 end if;
 select * into prior from public.issues where id=target_id and organization_id=p.organization_id for update;
 if not found then raise exception 'NOT_FOUND' using errcode='P0002'; end if;
 if prior.status not in ('DETECTED','PENDING_REVIEW') then raise exception 'INVALID_TRANSITION' using errcode='22023'; end if;
 update public.issues set status=decision,reviewed_by=p.id,updated_at=now() where id=target_id returning * into result;
 insert into public.audit_logs(organization_id,actor_user_id,action,object_type,object_id,previous_values,new_values,reason,correlation_id) values(p.organization_id,p.id,'REVIEW','ISSUE',target_id,jsonb_build_object('status',prior.status),jsonb_build_object('id',result.id,'status',result.status),review_reason,request_id);
 return jsonb_build_object('success',true,'data',jsonb_build_object('id',result.id,'status',result.status));
end $$;
revoke all on function civic_private.review_issue(uuid,public.issue_status,text,uuid) from public,anon;
grant execute on function civic_private.review_issue(uuid,public.issue_status,text,uuid) to authenticated;
create function public.review_issue(target_id uuid,decision public.issue_status,review_reason text,request_id uuid) returns jsonb language sql security invoker set search_path='' as $$select civic_private.review_issue(target_id,decision,review_reason,request_id)$$;
revoke all on function public.issues_in_view(double precision,double precision,double precision,double precision,public.issue_severity),public.city_statistics(),public.review_issue(uuid,public.issue_status,text,uuid) from public,anon;
grant execute on function public.issues_in_view(double precision,double precision,double precision,double precision,public.issue_severity),public.city_statistics(),public.review_issue(uuid,public.issue_status,text,uuid) to authenticated;
commit;
