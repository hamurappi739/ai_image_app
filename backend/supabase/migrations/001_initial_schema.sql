-- AI Image Generator — initial schema
-- See docs/database_schema.md

-- ---------------------------------------------------------------------------
-- profiles: user profile and credit balance (free used + paid credits)
-- id matches auth.users.id (Supabase Auth)
-- ---------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  free_generations_used integer not null default 0,
  paid_credits integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_free_generations_used_nonneg
    check (free_generations_used >= 0),
  constraint profiles_paid_credits_nonneg
    check (paid_credits >= 0)
);

comment on table public.profiles is
  'User profile: free generations counter and paid credits balance';
comment on column public.profiles.free_generations_used is
  'Count of used free generations; compared to FREE_GENERATIONS_LIMIT on backend';
comment on column public.profiles.paid_credits is
  'Paid credits balance; 1 credit = 1 image generation';

-- ---------------------------------------------------------------------------
-- generations: image generation history per user
-- ---------------------------------------------------------------------------
create table public.generations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  prompt text not null,
  image_url text not null,
  payment_type text not null,
  created_at timestamptz not null default now(),
  constraint generations_payment_type_check
    check (payment_type in ('free', 'paid'))
);

comment on table public.generations is
  'History of image generations (prompt, result URL, free or paid)';
comment on column public.generations.payment_type is
  'How the generation was paid: free or paid';

-- ---------------------------------------------------------------------------
-- credit_transactions: audit log of credit grants and spends
-- amount: positive = credit, negative = debit
-- ---------------------------------------------------------------------------
create table public.credit_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  amount integer not null,
  transaction_type text not null,
  source text not null,
  description text,
  external_payment_id text,
  created_at timestamptz not null default now(),
  constraint credit_transactions_transaction_type_check
    check (
      transaction_type in (
        'purchase',
        'generation_spend',
        'admin_adjustment',
        'refund'
      )
    ),
  constraint credit_transactions_source_check
    check (
      source in ('free', 'paid', 'rustore', 'admin', 'system')
    )
);

comment on table public.credit_transactions is
  'Immutable log of credit purchases, spends, refunds, and adjustments';
comment on column public.credit_transactions.amount is
  'Positive for grants, negative for spends';
comment on column public.credit_transactions.external_payment_id is
  'RuStore / payment webhook id for idempotency and support';

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index idx_generations_user_id
  on public.generations (user_id);

create index idx_generations_created_at
  on public.generations (created_at);

create index idx_credit_transactions_user_id
  on public.credit_transactions (user_id);

create index idx_credit_transactions_created_at
  on public.credit_transactions (created_at);

create index idx_credit_transactions_external_payment_id
  on public.credit_transactions (external_payment_id);

-- ---------------------------------------------------------------------------
-- Auto-update profiles.updated_at on row change
-- ---------------------------------------------------------------------------
create or replace function public.set_profiles_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row
  execute function public.set_profiles_updated_at();

-- TODO: Add RLS policies before production.
