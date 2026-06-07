-- Payment transactions for RuStore and future providers (idempotent purchase verification).

create table public.payment_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  provider text not null,
  provider_payment_id text not null,
  package_id text not null,
  amount_rub integer not null,
  paid_image_generations integer not null default 0,
  paid_photoshoots integer not null default 0,
  status text not null default 'verified',
  raw_payload jsonb null,
  created_at timestamptz not null default now(),
  constraint payment_transactions_provider_payment_unique
    unique (provider, provider_payment_id),
  constraint payment_transactions_status_check
    check (status in ('pending', 'verified', 'rejected', 'already_processed')),
  constraint payment_transactions_amount_rub_positive
    check (amount_rub > 0),
  constraint payment_transactions_paid_image_generations_nonneg
    check (paid_image_generations >= 0),
  constraint payment_transactions_paid_photoshoots_nonneg
    check (paid_photoshoots >= 0)
);

create index payment_transactions_user_id_idx
  on public.payment_transactions (user_id);

create index payment_transactions_provider_payment_id_idx
  on public.payment_transactions (provider_payment_id);

create index payment_transactions_created_at_idx
  on public.payment_transactions (created_at desc);

comment on table public.payment_transactions is
  'Verified store purchases; unique (provider, provider_payment_id) prevents double credit';
