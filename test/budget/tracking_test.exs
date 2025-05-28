defmodule Budget.TrackingTest do
  alias Budget.TrackingFixtures
  alias Budget.TrackingFixtures
  use Budget.DataCase

  alias Budget.AccountsFixtures
  alias Budget.TrackingFixtures
  alias Budget.Tracking
  alias Budget.Tracking.Budget

  describe "budgets" do
    test "create_budget/2 with valid data creator budget" do
      user = AccountsFixtures.user_fixture()

      valid_attrs = TrackingFixtures.valid_budget_attributes(%{creator_id: user.id})

      assert {:ok, %Budget{} = budget} = Tracking.create_budget(valid_attrs)

      assert budget.name == "some name"
      assert budget.description == "some description"
      assert budget.start_date == ~D[2025-01-01]
      assert budget.end_date == ~D[2025-01-31]
      assert budget.creator_id == user.id
    end

    test "create_budget/2 requires name" do
      attrs_without_name =
        TrackingFixtures.valid_budget_attributes()
        |> Map.delete(:name)

      assert {:error, %Ecto.Changeset{} = changeset} = Tracking.create_budget(attrs_without_name)

      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_budget/2 requires valid dates" do
      attrs_end_before_start =
        TrackingFixtures.valid_budget_attributes(%{
          start_date: ~D[2025-12-31],
          end_date: ~D[2025-01-01]
        })

      assert {:error, %Ecto.Changeset{} = changeset} =
               Tracking.create_budget(attrs_end_before_start)

      assert changeset.valid? == false
      assert %{end_date: ["must end after start date"]} = errors_on(changeset)
    end
  end
end
