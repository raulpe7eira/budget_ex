defmodule BudgetExWeb.Router do
  use BudgetExWeb, :router

  import BudgetExWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BudgetExWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BudgetExWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", BudgetExWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:budget_ex, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BudgetExWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BudgetExWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{BudgetExWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  scope "/", BudgetExWeb do
    pipe_through [:browser, :require_authenticated_user]

    post "/join/:code", JoinController, :join

    live_session :require_authenticated_user,
      on_mount: [{BudgetExWeb.UserAuth, :ensure_authenticated}] do
      live "/budgets", BudgetListLive
      live "/budgets/new", BudgetListLive, :new
      live "/budgets/:budget_id", BudgetShowLive
      live "/budgets/:budget_id/collaborators", BudgetShowLive, :collaborators
      live "/budgets/:budget_id/new-transaction", BudgetShowLive, :new_transaction

      live "/budgets/:budget_id/periods/:period_id", PeriodShowLive

      live "/budgets/:budget_id/periods/:period_id/new-transaction",
           PeriodShowLive,
           :new_transaction

      live "/budgets/:budget_id/periods/:period_id/transactions/:transaction_id/edit",
           PeriodShowLive,
           :edit_transaction

      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", BudgetExWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/join/:code", JoinController, :show_invitation

    live_session :current_user,
      on_mount: [{BudgetExWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
