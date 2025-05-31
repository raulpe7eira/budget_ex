defmodule BudgetWeb.BudgetShowLive do
  use BudgetWeb, :live_view

  alias Budget.Tracking

  def mount(%{"budget_id" => id}, _session, socket) when is_uuid(id) do
    budget =
      Tracking.get_budget(id,
        user: socket.assigns.current_user,
        preload: :creator
      )

    socket =
      if budget do
        assign(socket, budget: budget)
      else
        socket
        |> put_flash(:error, "Budget not found")
        |> redirect(to: ~p"/budgets")
      end

    {:ok, socket}
  end

  def mount(_invalid_id, _session, socket) do
    socket =
      socket
      |> put_flash(:error, "Budget not found")
      |> redirect(to: ~p"/budgets")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    {@budget.name} by {@budget.creator.name}
    """
  end
end
