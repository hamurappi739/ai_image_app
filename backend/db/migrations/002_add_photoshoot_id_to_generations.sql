-- Add optional photoshoot_id for grouping multi-image photoshoot results.
-- Nullable: regular /generate records and legacy rows remain valid without a group id.

alter table public.generations
  add column if not exists photoshoot_id uuid null;

comment on column public.generations.photoshoot_id is
  'Shared id for all images from one photoshoot session; null for regular generations';

create index if not exists generations_photoshoot_id_idx
  on public.generations (photoshoot_id);
