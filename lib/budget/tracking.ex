defmodule Budget.Tracking do
  import Ecto.Query, warn: false

  alias Budget.Repo
  alias Budget.Tracking.Budget

  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> Budget.changeset(attrs)
    |> Repo.insert()
  end

  def list_budgets, do: list_budgets([])

  def list_budgets(criteria) when is_list(criteria) do
    criteria
    |> budget_query()
    |> Repo.all()
  end

  def get_budget(id, criteria \\ []) do
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
end
