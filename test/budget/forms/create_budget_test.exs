defmodule Budget.Tracking.Forms.CreateBudgetTest do
  use Budget.DataCase, async: true

  alias Budget.Tracking.Forms.CreateBudget

  describe "submit/2" do
    test "creates a budget" do
      user = insert(:user)

      form = Phoenix.Component.to_form(CreateBudget.new())

      attrs = %{
        "budget" => string_params_for(:budget, creator_id: user.id)
      }

      result = CreateBudget.submit(form, attrs)

      assert {:ok, %{budget: budget}} = result
      assert budget.creator_id == user.id
    end
  end
end
