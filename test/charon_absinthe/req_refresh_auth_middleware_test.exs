defmodule CharonAbsinthe.ReqRefreshAuthMiddlewareTest do
  use ExUnit.Case, async: true
  use Charon.Internal.Constants
  alias Plug.Conn

  alias CharonAbsinthe.{ReqRefreshAuthMiddleware}
  alias Absinthe.Resolution

  @config %{
    optional_modules: %{
      CharonAbsinthe =>
        CharonAbsinthe.Config.from_enum(
          access_token_pipeline: __MODULE__.Authorized,
          refresh_token_pipeline: __MODULE__.Authorized,
          auth_error_handler: &__MODULE__.handle_auth_error/2
        )
    }
  }

  defmodule Authorized do
    def call(conn, _), do: Plug.Conn.assign(conn, :user_id, 1)
  end

  defmodule Unauthorized do
    def call(conn, _), do: Charon.Internal.auth_error(conn, "boom!")
  end

  def handle_auth_error(resolution, reason) do
    Resolution.put_result(resolution, {:error, reason})
  end

  describe "call/2" do
    test "ignores context's auth_error / assigns (from access token)" do
      resolution = %Resolution{
        state: :unresolved,
        context: %{@auth_error => "boom", charon_conn: %Conn{assigns: %{user_id: 2}}}
      }

      result = resolution |> ReqRefreshAuthMiddleware.call(@config)

      assert %{resolution | context: %{user_id: 1, charon_conn: %Conn{assigns: %{user_id: 1}}}} ==
               result
    end

    test "rejects unauthorized requests (according to refresh token pipeline)" do
      resolution = %Resolution{state: :unresolved, context: %{charon_conn: %Conn{}}}

      config = %{
        optional_modules: %{
          CharonAbsinthe =>
            CharonAbsinthe.Config.from_enum(
              access_token_pipeline: __MODULE__.Authorized,
              refresh_token_pipeline: __MODULE__.Unauthorized,
              auth_error_handler: &__MODULE__.handle_auth_error/2
            )
        }
      }

      result = resolution |> ReqRefreshAuthMiddleware.call(config)

      assert %{
               resolution
               | state: :resolved,
                 errors: ["boom!"],
                 context: %{charon_conn: %Conn{private: %{@auth_error => "boom!"}}}
             } == result
    end

    test "merges refresh token pipeline's resulting conn's assigns into context" do
      resolution = %Resolution{state: :unresolved, context: %{charon_conn: %Conn{}}}
      result = resolution |> ReqRefreshAuthMiddleware.call(@config)

      assert %{resolution | context: %{user_id: 1, charon_conn: %Conn{assigns: %{user_id: 1}}}} ==
               result
    end
  end
end
