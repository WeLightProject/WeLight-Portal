defmodule SuperIssuerWeb.Router do
  use SuperIssuerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SuperIssuerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", SuperIssuerWeb do
    pipe_through :browser
    get "/", IndexController, :index
    post "/", IndexController, :index

    get "/test", TestController, :index

    resources "/user/registrations", UserController, only: [:create, :new]
    get "/user/sign-in", SessionController, :new
    post "/user/sign-in", SessionController, :create
    get "/user", UserController, :index

    get "/credential/show", CredentialController, :index

    live "/live/clock", ClockLive
    live "/live/credential", CredentialLive
    live "/live/credential/new", CredentialLive.New
    live "/live/contract", ContractLive
    live "/live/evidence", EvidencerLive

    live "/live/top", TopLive

    live "/live/nodeshow", NodeShowLive

    live "/live/event", EventLive

    live "/live/app", AppLive
    live "/live/admin", AdminLive

    # live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  scope "/api/v1", SuperIssuerWeb do
    pipe_through :api
    get "/contracts", AppController, :get_contracts
    post "/contract/func", AppController, :interact_with_contract
    post "/weid/create", AppController, :create_weid
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: SuperIssuerWeb.Telemetry
    end
  end
end
