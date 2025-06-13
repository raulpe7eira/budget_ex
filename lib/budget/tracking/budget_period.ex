defmodule Budget.Tracking.BudgetPeriod do
  use Ecto.Schema
  import Ecto.Changeset

  alias Budget.Validations

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "budget_periods" do
    field :start_date, :date
    field :end_date, :date

    belongs_to :budget, Budget.Tracking.Budget

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(budget_period, attrs) do
    budget_period
    |> cast(attrs, [:start_date, :end_date, :budget_id])
    |> validate_required([:start_date, :end_date, :budget_id])
    |> check_constraint(:end_date,
      name: :end_after_start,
      message: "must end after start date"
    )
    |> unique_constraint([:budget_id, :start_Date])
    |> Validations.validate_date_month_boundaries()
  end
end
