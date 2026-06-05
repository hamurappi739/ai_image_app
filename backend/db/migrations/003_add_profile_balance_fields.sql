-- Add paid image and photoshoot balance fields to profiles.
-- paid_credits is retained for legacy / current credit consumption path.

alter table public.profiles
  add column if not exists paid_image_generations integer not null default 0,
  add column if not exists paid_photoshoots integer not null default 0;

alter table public.profiles
  add constraint profiles_paid_image_generations_nonneg
    check (paid_image_generations >= 0);

alter table public.profiles
  add constraint profiles_paid_photoshoots_nonneg
    check (paid_photoshoots >= 0);

comment on column public.profiles.paid_image_generations is
  'Paid balance: single image generations (Create tab); shown in UI as images, not credits';

comment on column public.profiles.paid_photoshoots is
  'Paid balance: photoshoot sessions; shown in UI as photoshoots, not credits';
