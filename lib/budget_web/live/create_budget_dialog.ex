defmodule BudgetWeb.CreateBudgetDialog do
  use BudgetWeb, :live_component

  alias Budget.Tracking
  alias Budget.Tracking.Budget

  @impl true
  def update(assigns, socket) do
    changeset = Tracking.change_budget(%Budget{})

    socket =
      socket
      |> assign(assigns)
      |> assign(form: to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_event("validate", %{"budget" => params}, socket) do
    changeset =
      %Budget{}
      |> Tracking.change_budget(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("save", %{"budget" => params}, socket) do
    params = Map.put(params, "creator_id", socket.assigns.current_user.id)

    socket =
      case Tracking.create_budget(params) do
        {:ok, %Budget{} = budget} ->
          socket
          |> put_flash(:info, "Budget created")
          |> push_navigate(to: ~p"/budgets/#{budget}", replace: true)

        {:error, %Ecto.Changeset{} = changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end
end
