defmodule Budget.Tracking do
  import Ecto.Query, warn: false

  alias Budget.Repo
  alias Budget.Accounts.User
  alias Budget.Tracking.BudgetTransaction
  alias Budget.Tracking.BudgetPeriod
  alias Budget.Tracking.BudgetJoinLink
  alias Budget.Tracking.BudgetCollaborator
  alias Budget.Tracking.Budget

  def list_budgets(criteria \\ []) when is_list(criteria) do
    criteria
    |> budget_query()
    |> Repo.all()
  end

  def get_budget(id, criteria \\ []) when is_list(criteria) do
    criteria
    |> budget_query()
    |> Repo.get(id)
  end

  def get_budget_by_join_code(code, criteria \\ []) when is_list(criteria) do
    [{:join_link_code, code} | criteria]
    |> budget_query()
    |> Repo.one()
  end

  defp budget_query(criteria) do
    query = from(b in Budget)

    Enum.reduce(criteria, query, fn
      {:user, user}, query ->
        from b in query,
          left_join: c in assoc(b, :collaborators),
          where: b.creator_id == ^user.id or c.user_id == ^user.id,
          distinct: true

      {:preload, bindings}, query ->
        preload(query, ^bindings)

      {:join_link_code, code}, query ->
        from b in query,
          join: l in assoc(b, :join_link),
          where: l.code == ^code

      _, query ->
        query
    end)
  end

  def get_budget_period(id, criteria \\ []) when is_list(criteria) do
    criteria
    |> budget_period_query()
    |> Repo.get(id)
  end

  def period_for_transaction(
        %BudgetTransaction{budget_id: budget_id, effective_date: effective_date},
        criteria \\ []
      )
      when is_list(criteria) do
    [{:budget_id, budget_id}, {:during, effective_date} | criteria]
    |> budget_period_query()
    |> Repo.one()
  end

  defp budget_period_query(criteria) do
    query = from(p in BudgetPeriod)

    Enum.reduce(criteria, query, fn
      {:user, user}, query ->
        from p in query,
          join: b in assoc(p, :budget),
          left_join: c in assoc(b, :collaborators),
          where: b.creator_id == ^user.id or c.user_id == ^user.id,
          distinct: true

      {:budget_id, budget_id}, query ->
        from p in query, where: p.budget_id == ^budget_id

      {:preload, bindings}, query ->
        preload(query, ^bindings)

      {:during, date}, query ->
        from p in query,
          where: fragment("? BETWEEN ? AND ?", ^date, p.start_date, p.end_date)

      _, query ->
        query
    end)
  end

  def create_transaction(%Budget{} = budget, attrs \\ %{}) do
    %BudgetTransaction{}
    |> BudgetTransaction.changeset(attrs, budget)
    |> Repo.insert()
  end

  def update_transaction(%BudgetTransaction{budget: %Budget{} = budget} = transaction, attrs) do
    update_transaction(budget, transaction, attrs)
  end

  def update_transaction(%Budget{} = budget, %BudgetTransaction{} = transaction, attrs) do
    transaction
    |> BudgetTransaction.changeset(attrs, budget)
    |> Repo.update()
  end

  def delete_transaction(%BudgetTransaction{} = transaction) do
    Repo.delete(transaction)
  end

  def list_transactions(budget_or_budget_id, criteria \\ [])

  def list_transactions(%Budget{id: budget_id}, criteria) when is_list(criteria),
    do: list_transactions(budget_id, criteria)

  def list_transactions(budget_id, criteria) when is_list(criteria) do
    [{:budget, budget_id} | criteria]
    |> transaction_query()
    |> Repo.all()
  end

  def change_transaction(
        %BudgetTransaction{budget: %Budget{} = budget} = transaction,
        attrs \\ %{}
      ) do
    BudgetTransaction.changeset(transaction, attrs, budget)
  end

  defp transaction_query(criteria) do
    query = from(f in BudgetTransaction, order_by: [asc: :effective_date])

    Enum.reduce(criteria, query, fn
      {:budget, budget_id}, query ->
        from t in query, where: t.budget_id == ^budget_id

      {:order_by, binding}, query ->
        from t in exclude(query, :order_by), order_by: ^binding

      {:preload, bindings}, query ->
        preload(query, ^bindings)

      {:between, {start_date, end_date}}, query ->
        from t in query,
          where: fragment("? BETWEEN ? AND ?", t.effective_date, ^start_date, ^end_date)

      _, query ->
        query
    end)
  end

  def summarize_transactions(%Budget{id: budget_id}),
    do: summarize_transactions(budget_id)

  def summarize_transactions(budget_id) do
    query =
      from t in transaction_query(budget: budget_id, order_by: nil),
        join: p in BudgetPeriod,
        on:
          t.budget_id == p.budget_id and
            fragment("? BETWEEN ? AND ?", t.effective_date, p.start_date, p.end_date),
        select: [p.id, t.type, sum(t.amount)],
        group_by: fragment("GROUPING SETS ((?, ?), ?)", p.id, t.type, t.type)

    query
    |> Repo.all()
    |> Enum.reduce(%{}, fn
      [nil, type, amount], summary ->
        Map.update(summary, :total, %{type => amount}, fn existing ->
          Map.put(existing, type, amount)
        end)

      [period_id, type, amount], summary ->
        Map.update(summary, period_id, %{type => amount}, fn existing ->
          Map.put(existing, type, amount)
        end)
    end)
  end

  def ensure_join_link(%Budget{} = budget) do
    %BudgetJoinLink{}
    |> BudgetJoinLink.changeset(%{budget_id: budget.id})
    |> Repo.insert(
      conflict_target: :budget_id,
      on_conflict: {:replace, [:updated_at]},
      returning: true
    )
  end

  def ensure_budget_collaborator(%Budget{id: budget_id}, %User{id: user_id}) do
    %BudgetCollaborator{}
    |> BudgetCollaborator.changeset(%{budget_id: budget_id, user_id: user_id})
    |> Repo.insert(
      conflict_target: [:budget_id, :user_id],
      on_conflict: {:replace, [:updated_at]}
    )
  end

  def remove_budget_collaborator(%BudgetCollaborator{} = collaborator) do
    Repo.delete(collaborator)
  end
end
