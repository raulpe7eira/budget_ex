defmodule Budget.TrackingTest do
  use Budget.DataCase

  alias Budget.AccountsFixtures
  alias Budget.TrackingFixtures
  alias Budget.Tracking
  alias Budget.Tracking.Budget

  describe "budgets" do
    test "create_budget/1 with valid data creator budget" do
      user = AccountsFixtures.user_fixture()

      valid_attrs = TrackingFixtures.valid_budget_attributes(%{creator_id: user.id})

      assert {:ok, %Budget{} = budget} = Tracking.create_budget(valid_attrs)

      assert budget.name == "some name"
      assert budget.description == "some description"
      assert budget.start_date == ~D[2025-01-01]
      assert budget.end_date == ~D[2025-01-31]
      assert budget.creator_id == user.id
    end

    test "create_budget/1 requires name" do
      attrs_without_name =
        TrackingFixtures.valid_budget_attributes()
        |> Map.delete(:name)

      assert {:error, %Ecto.Changeset{} = changeset} = Tracking.create_budget(attrs_without_name)

      assert changeset.valid? == false
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "create_budget/1 requires valid dates" do
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

    test "list_budgets/0 returns all budgets" do
      budget = TrackingFixtures.budget_fixture()

      assert Tracking.list_budgets() == [budget]
    end

    test "list_budgets/1 scopes to the provided user" do
      user = AccountsFixtures.user_fixture()

      budget = TrackingFixtures.budget_fixture(%{creator_id: user.id})
      _other_budget = TrackingFixtures.budget_fixture()

      assert Tracking.list_budgets(user: user) == [budget]
    end

    test "get_budget/1 returns the budget with given id" do
      budget = TrackingFixtures.budget_fixture()

      assert Tracking.get_budget(budget.id) == budget
    end

    test "get_budget/1 returns nil when budget doesn't exist" do
      _other_budget = TrackingFixtures.budget_fixture()

      assert is_nil(Tracking.get_budget("10fe1ad8-6133-5d7d-b5c9-da29581bb923"))
    end
  end
end
