-- Supabase 存储配置和 RLS 策略

-- 创建存储 bucket (需要在 SQL Editor 中以 superuser 执行)
-- insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
-- values (
--   'checkin-videos',
--   'checkin-videos',
--   false,
--   104857600,
--   array['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/x-matroska', 'video/webm']
-- );

-- 存储桶 RLS 策略
-- 家长可上传自己孩子的视频
create policy "家长可上传视频"
on storage.objects for insert
to authenticated
with check (
    bucket_id = 'checkin-videos'
);

-- 家长可查看自己上传的视频
create policy "家长可查看自己的视频"
on storage.objects for select
to authenticated
using (
    bucket_id = 'checkin-videos'
    and (storage.foldername(name))[1] in (
        select id::text from public.children where parent_id = auth.uid()
    )
);

-- 治疗师可查看自己患者的视频
create policy "治疗师可查看患者视频"
on storage.objects for select
to authenticated
using (
    bucket_id = 'checkin-videos'
    and (storage.foldername(name))[1] in (
        select id::text from public.children where therapist_id = auth.uid()
    )
);

-- 机构管理员可查看本机构视频
create policy "管理员可查看本机构视频"
on storage.objects for select
to authenticated
using (
    bucket_id = 'checkin-videos'
    and exists (
        select 1 from public.profiles p
        where p.id = auth.uid()
        and p.role = 'admin'
    )
);
