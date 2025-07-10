defmodule BudgetWeb.CreateBudgetDialog do
  use BudgetWeb, :live_component

  alias Budget.Tracking.Forms.CreateBudget
  alias Budget.Tracking.Budget

  @impl true
  def update(assigns, socket) do
    changeset = CreateBudget.new()

    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"create_budget" => params}, socket) do
    changeset =
      CreateBudget.new()
      |> CreateBudget.changeset(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"create_budget" => params}, socket) do
    params = put_in(params, ["budget", "creator_id"], socket.assigns.current_user.id)

    socket =
      case CreateBudget.submit(socket.assigns.form, params) do
        {:ok, %{budget: %Budget{} = budget}} ->
          socket
          |> put_flash(:info, "Budget created")
          |> push_navigate(to: ~p"/budgets/#{budget}", replace: true)

        {:error, %Ecto.Changeset{} = changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end
end
