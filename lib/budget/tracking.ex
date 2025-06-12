defmodule Budget.Tracking do
  import Ecto.Query, warn: false

  alias Budget.Repo
  alias Budget.Tracking.BudgetTransaction
  alias Budget.Tracking.Budget

  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> Budget.changeset(attrs)
    |> Repo.insert()
  end

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

  def change_budget(budget, attrs \\ %{}) do
    Budget.changeset(budget, attrs)
  end

  defp budget_query(criteria) do
    query = from(b in Budget)

    criteria
    |> Enum.reduce(query, fn
      {:user, user}, query ->
        from b in query, where: b.creator_id == ^user.id

      {:preload, bindings}, query ->
        preload(query, ^bindings)

      _, query ->
        query
    end)
  end

  def create_transaction(attrs \\ %{}) do
    %BudgetTransaction{}
    |> BudgetTransaction.changeset(attrs)
    |> Repo.insert()
  end

  def update_transaction(%BudgetTransaction{} = transaction, attrs) do
    transaction
    |> BudgetTransaction.changeset(attrs)
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

  def change_transaction(budget_transaction, attrs \\ %{}) do
    BudgetTransaction.changeset(budget_transaction, attrs)
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

      _, query ->
        query
    end)
  end

  def summarize_transactions(%Budget{id: budget_id}),
    do: summarize_transactions(budget_id)

  def summarize_transactions(budget_id) do
    query =
      from t in transaction_query(budget: budget_id, order_by: nil),
        select: [t.type, sum(t.amount)],
        group_by: t.type

    query
    |> Repo.all()
    |> Enum.reduce(%{}, fn [type, amount], summary ->
      Map.put(summary, type, amount)
    end)
  end
end
