# CharonAbsinthe

CharonAbsinthe is an extension package for [Charon](https://hexdocs.pm/charon) to use it with [Absinthe](https://hexdocs.pm/absinthe).

## Table of contents

<!-- TOC -->

- [CharonAbsinthe](#charonabsinthe)
  - [Table of contents](#table-of-contents)
  - [Documentation](#documentation)
  - [How to use](#how-to-use)
    - [Installation](#installation)
    - [Setup the parent package](#setup-the-parent-package)
    - [Create an error handler](#create-an-error-handler)
    - [Configuration](#configuration)
    - [Configure router](#configure-router)
    - [Protect your schema](#protect-your-schema)
    - [Create a session resolver](#create-a-session-resolver)

<!-- /TOC -->

## Documentation

Documentation (including this readme with module links resolved) can be found at [https://hexdocs.pm/charon_absinthe](https://hexdocs.pm/charon_absinthe).

## How to use

### Installation

The package can be installed by adding `charon_absinthe` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:charon_absinthe, "~> 0.0.0+development"}
  ]
end
```

### Setup the parent package

Follow the `Charon` [readme](https://hexdocs.pm/charon/readme.html#protecting-routes) until you've created token pipelines.

### Create an error handler

```elixir
defmodule MyAppWeb.Absinthe do
  def authentication_error(resolution, auth_error_msg) do
    message = "request could not be authenticated: \#{auth_error_msg}"
    extensions = %{error: "authentication_failure", reason: auth_error_msg}
    error = %{message: message, extensions: extensions}
    Absinthe.Resolution.put_result(resolution, {:error, error})
  end
end
```

### Configuration

Additional config is required, see `CharonAbsinthe.Config`.

### Configure router

Add a pipeline with the `CharonAbsinthe.HydrateContextPlug`, route the graphql endpoint through it,
and register the `CharonAbsinthe.send_context_cookies/2` callback as an `Absinthe.Plug` `:before_send` hook.

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  @config Application.compile_env(:my_app, :charon) |> Charon.Config.from_enum()

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :charon_auth do
    plug CharonAbsinthe.HydrateContextPlug, @config
  end

  scope "/api" do
    pipe_through :charon_auth

    forward "/graphql", Absinthe.Plug,
      schema: MyAppWeb.Absinthe.Schema,
      before_send: {CharonAbsinthe, :send_context_cookies}
  end
end
```

### Protect your schema

Normal "auth-required" fields must be protected with `CharonAbsinthe.ReqAuthMiddleware`.
The refresh mutation must be protected with `CharonAbsinthe.ReqRefreshAuthMiddleware`.
Mutations that alter the session (login, logout, refresh, logout-all, logout-other...) must be followed by `CharonAbsinthe.PostSessionChangeMiddleware`.

```elixir
defmodule MyAppWeb.Absinthe.SessionTypes do
  use Absinthe.Schema.Notation
  alias MyAppWeb.Absinthe.SessionResolver
  alias CharonAbsinthe.{ReqAuthMiddleware, ReqRefreshAuthMiddleware, PostSessionChangeMiddleware}

  @config Application.compile_env(:my_app, :charon) |> Charon.Config.from_enum()

  object :session_mutations do
    field :login, type: :login_payload do
      arg :email, non_null(:string)
      arg :password, non_null(:string)
      arg :token_signature_transport, non_null(:string)
      resolve &SessionResolver.login/3
      middleware PostSessionChangeMiddleware
    end

    field :logout, type: :logout_payload do
      middleware ReqAuthMiddleware, @config
      resolve &SessionResolver.logout/3
      middleware PostSessionChangeMiddleware
    end

    field :refresh, type: :refresh_payload do
      middleware ReqRefreshAuthMiddleware, @config
      resolve &SessionResolver.refresh/3
      middleware PostSessionChangeMiddleware
    end
  end
end
```

### Create a session resolver

Error handling is omitted.

```elixir
defmodule MyAppWeb.Absinthe.SessionResolver do
  alias Charon.{Utils, SessionPlugs}
  alias MyApp.{User, Users}

  @config Application.compile_env(:my_app, :charon) |> Charon.Config.from_enum()

  def login(
        _parent,
        _args = %{token_signature_transport: transport, email: email, password: password},
        _resolution = %{context: %{charon_conn: conn}}
      ) do
    with {:ok, user} <- Users.get_by(email: email) |> Users.verify_password(password) do
      conn
      |> Utils.set_token_signature_transport(transport)
      |> Utils.set_user_id(user.id)
      |> SessionPlugs.upsert_session(@config)
      |> token_response()
    end
  end

  def logout(_parent, _args, _resolution = %{context: %{charon_conn: conn}}) do
    conn
    |> SessionPlugs.delete_session(@config)
    |> then(fn conn -> {:ok, %{resp_cookies: conn.resp_cookies}} end)
  end

  def refresh(
        _parent,
        _args,
        _resolution = %{context: %{charon_conn: conn, user_id: user_id}}
      ) do
    with %User{status: "active"} <- Users.get_by(id: user_id) do
      conn |> SessionPlugs.upsert_session(@config) |> token_response()
    end
  end

  ###########
  # Private #
  ###########

  defp token_response(conn) do
    tokens = conn |> Utils.get_tokens() |> Map.from_struct()
    session = conn |> Utils.get_session() |> Map.from_struct()
    {:ok, %{resp_cookies: conn.resp_cookies, tokens: tokens, session: session}}
  end
end
```
