defmodule Budget.Tracking do
  import Ecto.Query, warn: false

  alias Budget.Repo
  alias Budget.Tracking.Budget

  def create_budget(attrs \\ %{}) do
    %Budget{}
    |> Budget.changeset(attrs)
    |> Repo.insert()
  end

  def list_budgets, do: Repo.all(Budget)

  def get_budget(id), do: Repo.get(Budget, id)
end
