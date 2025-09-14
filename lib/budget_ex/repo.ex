defmodule BudgetEx.Repo do
  use Ecto.Repo,
    otp_app: :budget_ex,
    adapter: Ecto.Adapters.Postgres
end
