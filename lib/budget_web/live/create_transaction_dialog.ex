defmodule BudgetWeb.CreateTransactionDialog do
  use BudgetWeb, :live_component

  alias Budget.Tracking
  alias Budget.Tracking.BudgetTransaction

  @impl true
  def update(assigns, socket) do
    changeset = Tracking.change_transaction(default_transaction())

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"transaction" => params}, socket) do
    changeset =
      default_transaction()
      |> Tracking.change_transaction(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"transaction" => params}, socket) do
    budget = socket.assigns.budget

    params = Map.put(params, "budget_id", budget.id)

    socket =
      case Tracking.create_transaction(params) do
        {:ok, %BudgetTransaction{}} ->
          socket
          |> put_flash(:info, "Transaction created")
          |> push_navigate(to: ~p"/budgets/#{budget}", replace: true)

        {:error, %Ecto.Changeset{} = changeset} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  defp default_transaction do
    %BudgetTransaction{effective_date: Date.utc_today()}
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: "transaction"))
  end
end
