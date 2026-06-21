-- 儿童康复训练家庭作业系统 数据库 Schema

-- 启用必要的扩展
create extension if not exists "uuid-ossp";

-- 机构表
create table if not exists public.institutions (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    address text,
    contact_phone text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 用户资料表（扩展 auth.users）
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    full_name text not null,
    phone text,
    avatar_url text,
    role text not null check (role in ('admin', 'therapist', 'parent')),
    institution_id uuid references public.institutions(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 孩子表
create table if not exists public.children (
    id uuid primary key default uuid_generate_v4(),
    name text not null,
    nickname text,
    birth_date date,
    gender text check (gender in ('male', 'female', 'other')),
    avatar_url text,
    notes text,
    parent_id uuid not null references public.profiles(id) on delete cascade,
    therapist_id uuid references public.profiles(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 训练类型枚举
create type if not exists exercise_type as enum ('pronunciation', 'fine_motor', 'sensory');

-- 作业模板表（治疗师创建的标准作业）
create table if not exists public.homework_templates (
    id uuid primary key default uuid_generate_v4(),
    title text not null,
    description text,
    exercise_type exercise_type not null,
    therapist_id uuid not null references public.profiles(id) on delete cascade,
    institution_id uuid references public.institutions(id) on delete set null,
    is_public boolean default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 作业步骤表
create table if not exists public.homework_steps (
    id uuid primary key default uuid_generate_v4(),
    template_id uuid not null references public.homework_templates(id) on delete cascade,
    step_number integer not null,
    title text not null,
    description text,
    image_url text,
    video_url text,
    duration_seconds integer default 0,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 已布置的作业表
create table if not exists public.assigned_homeworks (
    id uuid primary key default uuid_generate_v4(),
    template_id uuid references public.homework_templates(id) on delete set null,
    child_id uuid not null references public.children(id) on delete cascade,
    therapist_id uuid not null references public.profiles(id) on delete cascade,
    title text not null,
    description text,
    exercise_type exercise_type not null,
    start_date date not null,
    end_date date not null,
    frequency_per_week integer default 1,
    status text not null default 'pending' check (status in ('pending', 'in_progress', 'completed', 'reviewed')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 打卡记录表
create table if not exists public.check_ins (
    id uuid primary key default uuid_generate_v4(),
    assigned_homework_id uuid not null references public.assigned_homeworks(id) on delete cascade,
    parent_id uuid not null references public.profiles(id) on delete cascade,
    child_id uuid not null references public.children(id) on delete cascade,
    check_in_date date not null,
    completed_steps jsonb default '[]'::jsonb,
    notes text,
    mood text check (mood in ('happy', 'good', 'neutral', 'tired', 'unwilling')),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- 视频上传表
create table if not exists public.videos (
    id uuid primary key default uuid_generate_v4(),
    check_in_id uuid not null references public.check_ins(id) on delete cascade,
    step_id uuid references public.homework_steps(id) on delete set null,
    storage_path text not null,
    thumbnail_url text,
    duration_seconds integer,
    file_size bigint,
    created_at timestamptz not null default now()
);

-- 治疗师评审表
create table if not exists public.reviews (
    id uuid primary key default uuid_generate_v4(),
    check_in_id uuid not null references public.check_ins(id) on delete cascade,
    therapist_id uuid not null references public.profiles(id) on delete cascade,
    overall_rating integer check (overall_rating between 1 and 5),
    action_correct boolean,
    feedback text,
    next_adjustment text,
    step_reviews jsonb default '[]'::jsonb,
    video_annotations jsonb default '[]'::jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (check_in_id, therapist_id)
);

-- 创建索引
create index if not exists idx_children_parent on public.children(parent_id);
create index if not exists idx_children_therapist on public.children(therapist_id);
create index if not exists idx_homeworks_child on public.assigned_homeworks(child_id);
create index if not exists idx_homeworks_therapist on public.assigned_homeworks(therapist_id);
create index if not exists idx_checkins_homework on public.check_ins(assigned_homework_id);
create index if not exists idx_checkins_child on public.check_ins(child_id);
create index if not exists idx_videos_checkin on public.videos(check_in_id);
create index if not exists idx_reviews_checkin on public.reviews(check_in_id);

-- 自动更新时间戳触发器
create or replace function public.handle_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql security definer;

create trigger handle_institutions_updated_at
    before update on public.institutions
    for each row execute function public.handle_updated_at();

create trigger handle_profiles_updated_at
    before update on public.profiles
    for each row execute function public.handle_updated_at();

create trigger handle_children_updated_at
    before update on public.children
    for each row execute function public.handle_updated_at();

create trigger handle_templates_updated_at
    before update on public.homework_templates
    for each row execute function public.handle_updated_at();

create trigger handle_steps_updated_at
    before update on public.homework_steps
    for each row execute function public.handle_updated_at();

create trigger handle_assigned_homeworks_updated_at
    before update on public.assigned_homeworks
    for each row execute function public.handle_updated_at();

create trigger handle_checkins_updated_at
    before update on public.check_ins
    for each row execute function public.handle_updated_at();

create trigger handle_reviews_updated_at
    before update on public.reviews
    for each row execute function public.handle_updated_at();

-- RLS (行级安全策略)
alter table public.institutions enable row level security;
alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.homework_templates enable row level security;
alter table public.homework_steps enable row level security;
alter table public.assigned_homeworks enable row level security;
alter table public.check_ins enable row level security;
alter table public.videos enable row level security;
alter table public.reviews enable row level security;

-- Profiles 策略
create policy "用户可查看自己的资料"
    on public.profiles for select
    using (auth.uid() = id);

create policy "机构管理员可查看本机构所有资料"
    on public.profiles for select
    using (
        exists (
            select 1 from public.profiles p
            where p.id = auth.uid()
            and p.role = 'admin'
            and p.institution_id = profiles.institution_id
        )
    );

create policy "治疗师可查看自己的患者家长资料"
    on public.profiles for select
    using (
        exists (
            select 1 from public.children c
            where c.therapist_id = auth.uid()
            and c.parent_id = profiles.id
        )
    );

create policy "家长可查看自己孩子治疗师资料"
    on public.profiles for select
    using (
        exists (
            select 1 from public.children c
            where c.parent_id = auth.uid()
            and c.therapist_id = profiles.id
        )
    );

create policy "用户可更新自己的资料"
    on public.profiles for update
    using (auth.uid() = id);

-- Children 策略
create policy "家长可查看自己的孩子"
    on public.children for select
    using (parent_id = auth.uid());

create policy "治疗师可查看自己的患者"
    on public.children for select
    using (therapist_id = auth.uid());

create policy "机构管理员可查看本机构所有孩子"
    on public.children for select
    using (
        exists (
            select 1 from public.profiles p
            where p.id = auth.uid()
            and p.role = 'admin'
            and p.institution_id = (
                select institution_id from public.profiles where id = children.therapist_id
            )
        )
    );

create policy "家长可添加孩子"
    on public.children for insert
    with check (parent_id = auth.uid());

create policy "治疗师可分配自己为治疗师"
    on public.children for update
    using (
        exists (
            select 1 from public.profiles p
            where p.id = auth.uid() and p.role = 'therapist'
        )
    );

-- Homework Templates 策略
create policy "治疗师可查看自己和公开的作业模板"
    on public.homework_templates for select
    using (therapist_id = auth.uid() or is_public = true);

create policy "治疗师可创建作业模板"
    on public.homework_templates for insert
    with check (therapist_id = auth.uid());

create policy "治疗师可更新自己的作业模板"
    on public.homework_templates for update
    using (therapist_id = auth.uid());

-- Homework Steps 策略
create policy "可查看作业模板的步骤"
    on public.homework_steps for select
    using (
        exists (
            select 1 from public.homework_templates t
            where t.id = template_id
            and (t.therapist_id = auth.uid() or t.is_public = true)
        )
    );

create policy "模板所有者可增删改步骤"
    on public.homework_steps for all
    using (
        exists (
            select 1 from public.homework_templates t
            where t.id = template_id and t.therapist_id = auth.uid()
        )
    );

-- Assigned Homeworks 策略
create policy "家长可查看自己孩子的作业"
    on public.assigned_homeworks for select
    using (
        exists (
            select 1 from public.children c
            where c.id = child_id and c.parent_id = auth.uid()
        )
    );

create policy "治疗师可查看自己布置的作业"
    on public.assigned_homeworks for select
    using (therapist_id = auth.uid());

create policy "机构管理员可查看本机构作业"
    on public.assigned_homeworks for select
    using (
        exists (
            select 1 from public.profiles p
            where p.id = auth.uid() and p.role = 'admin'
            and p.institution_id = (
                select institution_id from public.profiles where id = therapist_id
            )
        )
    );

create policy "治疗师可布置作业"
    on public.assigned_homeworks for insert
    with check (therapist_id = auth.uid());

create policy "治疗师可更新自己布置的作业"
    on public.assigned_homeworks for update
    using (therapist_id = auth.uid());

-- Check-ins 策略
create policy "家长可查看自己的打卡"
    on public.check_ins for select
    using (parent_id = auth.uid());

create policy "治疗师可查看自己患者的打卡"
    on public.check_ins for select
    using (
        exists (
            select 1 from public.children c
            where c.id = child_id and c.therapist_id = auth.uid()
        )
    );

create policy "家长可创建打卡"
    on public.check_ins for insert
    with check (parent_id = auth.uid());

create policy "家长可更新自己的打卡"
    on public.check_ins for update
    using (parent_id = auth.uid());

-- Videos 策略
create policy "家长可查看自己上传的视频"
    on public.videos for select
    using (
        exists (
            select 1 from public.check_ins ci
            where ci.id = check_in_id and ci.parent_id = auth.uid()
        )
    );

create policy "治疗师可查看患者的视频"
    on public.videos for select
    using (
        exists (
            select 1 from public.check_ins ci
            join public.children c on c.id = ci.child_id
            where ci.id = check_in_id and c.therapist_id = auth.uid()
        )
    );

create policy "家长可上传视频"
    on public.videos for insert
    with check (
        exists (
            select 1 from public.check_ins ci
            where ci.id = check_in_id and ci.parent_id = auth.uid()
        )
    );

-- Reviews 策略
create policy "家长可查看自己孩子的评审"
    on public.reviews for select
    using (
        exists (
            select 1 from public.check_ins ci
            where ci.id = check_in_id and ci.parent_id = auth.uid()
        )
    );

create policy "治疗师可查看和创建自己的评审"
    on public.reviews for all
    using (therapist_id = auth.uid())
    with check (therapist_id = auth.uid());

-- Institutions 策略
create policy "机构管理员可查看自己的机构"
    on public.institutions for select
    using (
        exists (
            select 1 from public.profiles p
            where p.id = auth.uid() and p.role = 'admin'
            and p.institution_id = institutions.id
        )
    );

-- 创建存储 bucket
-- 需要在 Supabase 控制台手动创建名为 'checkin-videos' 的存储 bucket
-- 或者使用以下 SQL (需要 superuser):
-- insert into storage.buckets (id, name, public) values ('checkin-videos', 'checkin-videos', false);
