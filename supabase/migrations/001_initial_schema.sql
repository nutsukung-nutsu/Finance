-- Schema for the Finance app. Run in Supabase SQL Editor.
create table if not exists public.finance_transactions (
    id text primary key default gen_random_uuid()::text,
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null check (type in ('income', 'expense')),
    transaction_date date not null,
    amount numeric(14, 2) not null check (amount >= 0),
    category text not null,
    detail text not null default '',
    note text not null default '',
    created_at timestamptz not null default now()
);

create table if not exists public.finance_categories (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    type text not null check (type in ('income', 'expense')),
    name text not null check (length(trim(name)) > 0),
    memos jsonb not null default '[]'::jsonb check (jsonb_typeof(memos) = 'array'),
    icon text not null default 'fas fa-tag',
    color text not null default '#9ca3af',
    created_at timestamptz not null default now(),
    constraint finance_categories_user_type_name_key unique (user_id, type, name)
);

create index if not exists finance_transactions_user_date_idx
    on public.finance_transactions (user_id, transaction_date desc, created_at desc);
create index if not exists finance_categories_user_type_idx
    on public.finance_categories (user_id, type, name);

alter table public.finance_transactions enable row level security;
alter table public.finance_categories enable row level security;

revoke all on public.finance_transactions from anon, authenticated;
revoke all on public.finance_categories from anon, authenticated;
grant select, insert, update, delete on public.finance_transactions to authenticated;
grant select, insert, update, delete on public.finance_categories to authenticated;

drop policy if exists "Users manage their own transactions" on public.finance_transactions;
create policy "Users manage their own transactions"
    on public.finance_transactions for all to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

drop policy if exists "Users manage their own categories" on public.finance_categories;
create policy "Users manage their own categories"
    on public.finance_categories for all to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));
