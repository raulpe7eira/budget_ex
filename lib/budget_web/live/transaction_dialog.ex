defmodule BudgetWeb.TransactionDialog do
  use BudgetWeb, :live_component

  alias Budget.Tracking
  alias Budget.Tracking.BudgetTransaction

  @impl true
  def update(assigns, socket) do
    changeset = Tracking.change_transaction(assigns.transaction)

    socket =
      socket
      |> assign(assigns)
      |> assign_form(changeset)

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"transaction" => params}, socket) do
    changeset =
      socket.assigns.transaction
      |> Tracking.change_transaction(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"transaction" => params}, socket) do
    save_transaction(socket, socket.assigns.action, params)
  end

  @impl true
  def handle_event("delete_transaction", %{"id" => transaction_id}, socket) do
    transaction = Enum.find(socket.assigns.transactions, &(&1.id == transaction_id))

    socket =
      if transaction do
        case Tracking.delete_transaction(transaction) do
          {:ok, _} ->
            socket
            |> put_flash(:info, "Transaction deleted")
            |> redirect(to: ~p"/budgets/#{socket.assigns.budget.id}", replace: true)

          {:error, _} ->
            put_flash(socket, :error, "Failed to delete transaction")
        end
      else
        put_flash(socket, :error, "Trnasaction not found")
      end

    {:noreply, socket}
  end

  defp assign_form(socket, changeset) do
    assign(socket, form: to_form(changeset, as: "transaction"))
  end

  defp save_transaction(socket, :edit_transaction, params) do
    budget = socket.assigns.budget

    params = Map.put(params, "budget_id", budget.id)

    socket =
      case Tracking.update_transaction(socket.assigns.transaction, params) do
        {:ok, %BudgetTransaction{} = transaction} ->
          socket
          |> put_flash(:info, "Transaction updated")
          |> push_navigate(to: destination_on_success(transaction), replace: true)

        {:error, %Ecto.Changeset{} = changeset} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  defp save_transaction(socket, :new_transaction, params) do
    budget = socket.assigns.budget

    params = Map.put(params, "budget_id", budget.id)

    socket =
      case Tracking.create_transaction(budget, params) do
        {:ok, %BudgetTransaction{} = transaction} ->
          socket
          |> put_flash(:info, "Transaction created")
          |> push_navigate(to: destination_on_success(transaction), replace: true)

        {:error, %Ecto.Changeset{} = changeset} ->
          assign_form(socket, changeset)
      end

    {:noreply, socket}
  end

  defp destination_on_success(transaction) do
    period = Tracking.period_for_transaction(transaction)
    ~p"/budgets/#{period.budget_id}/periods/#{period.id}"
  end
end
