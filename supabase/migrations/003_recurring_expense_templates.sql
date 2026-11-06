-- User-managed monthly expense templates. Templates are applied only when the
-- user explicitly selects them for the current month.
create table if not exists public.finance_recurring_expenses (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    name text not null check (length(trim(name)) > 0),
    category text not null,
    amount numeric(14, 2) not null check (amount > 0),
    detail text not null default '',
    due_day smallint not null check (due_day between 1 and 31),
    created_at timestamptz not null default now(),
    constraint finance_recurring_expenses_user_name_key unique (user_id, name)
);

create index if not exists finance_recurring_expenses_user_idx
    on public.finance_recurring_expenses (user_id, created_at desc);

alter table public.finance_transactions
    add column if not exists recurring_expense_id uuid,
    add column if not exists recurring_period date;

alter table public.finance_transactions
    drop constraint if exists finance_transactions_recurring_pair_check;
alter table public.finance_transactions
    add constraint finance_transactions_recurring_pair_check
        check ((recurring_expense_id is null) = (recurring_period is null));

create unique index if not exists finance_transactions_recurring_once_per_month_idx
    on public.finance_transactions (user_id, recurring_expense_id, recurring_period)
    where recurring_expense_id is not null;

alter table public.finance_recurring_expenses enable row level security;
revoke all on public.finance_recurring_expenses from anon, authenticated;
grant select, insert, update, delete on public.finance_recurring_expenses to authenticated;

drop policy if exists "Users manage their own recurring expenses" on public.finance_recurring_expenses;
create policy "Users manage their own recurring expenses"
    on public.finance_recurring_expenses for all to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));
