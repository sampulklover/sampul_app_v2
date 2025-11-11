-- Create a public bucket for chat attachments
-- If this errors with "already exists", you can ignore it.
select storage.create_bucket('attachments', true);

-- Public read access for attachments (since app uses public URLs)
create policy "attachments public read"
on storage.objects
for select
using (bucket_id = 'attachments');

-- Allow any authenticated user to upload into attachments bucket
create policy "attachments authenticated can upload"
on storage.objects
for insert
with check (
  bucket_id = 'attachments'
  and auth.role() = 'authenticated'
);

-- Allow authenticated users to update objects in attachments bucket
create policy "attachments authenticated can update"
on storage.objects
for update
using (
  bucket_id = 'attachments'
  and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'attachments'
  and auth.role() = 'authenticated'
);

-- Allow authenticated users to delete objects in attachments bucket
create policy "attachments authenticated can delete"
on storage.objects
for delete
using (
  bucket_id = 'attachments'
  and auth.role() = 'authenticated'
);


