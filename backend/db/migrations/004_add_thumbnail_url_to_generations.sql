-- Gallery preview thumbnails (full image remains in image_url).
alter table public.generations
  add column if not exists thumbnail_url text;
