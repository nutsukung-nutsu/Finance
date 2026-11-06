-- Keep imported text IDs and prevent editing or deleting transactions after their month closes.
alter table public.finance_transactions
    alter column id drop default,
    alter column id type text using id::text,
    alter column id set default gen_random_uuid()::text;

drop policy if exists "Users manage their own transactions" on public.finance_transactions;
drop policy if exists "Users read their own transactions" on public.finance_transactions;
drop policy if exists "Users insert their own transactions" on public.finance_transactions;
drop policy if exists "Users update current-month transactions" on public.finance_transactions;
drop policy if exists "Users delete current-month transactions" on public.finance_transactions;

create policy "Users read their own transactions"
    on public.finance_transactions for select to authenticated
    using (user_id = (select auth.uid()));

create policy "Users insert their own transactions"
    on public.finance_transactions for insert to authenticated
    with check (user_id = (select auth.uid()));

create or replace function public.enforce_current_month_transaction_writes()
returns trigger
language plpgsql
set search_path = public
as $$
declare
    current_month_start date := date_trunc('month', timezone('Asia/Bangkok', now()))::date;
    next_month_start date := (date_trunc('month', timezone('Asia/Bangkok', now())) + interval '1 month')::date;
begin
    if tg_op = 'UPDATE' then
        if old.transaction_date < current_month_start or old.transaction_date >= next_month_start then
            raise exception 'Transactions from previous months are read-only';
        end if;
        if new.transaction_date < current_month_start or new.transaction_date >= next_month_start then
            raise exception 'Transactions can only be changed within the current month';
        end if;
        return new;
    end if;

    if tg_op = 'DELETE' then
        if old.transaction_date < current_month_start or old.transaction_date >= next_month_start then
            raise exception 'Transactions from previous months are read-only';
        end if;
        return old;
    end if;

    return new;
end;
$$;

drop trigger if exists finance_transactions_month_write_guard on public.finance_transactions;
create trigger finance_transactions_month_write_guard
    before update or delete on public.finance_transactions
    for each row execute function public.enforce_current_month_transaction_writes();

create policy "Users update current-month transactions"
    on public.finance_transactions for update to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

create policy "Users delete current-month transactions"
    on public.finance_transactions for delete to authenticated
    using (user_id = (select auth.uid()));
