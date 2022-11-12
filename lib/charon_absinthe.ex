defmodule CharonAbsinthe do
  @moduledoc Mix.Project.config()[:description]
  use CharonAbsinthe.Internal.Constants

  @doc false
  def init_config(enum), do: __MODULE__.Config.from_enum(enum)

  @doc false
  def get_module_config(%{optional_modules: %{CharonAbsinthe => config}}), do: config

  @doc """
  Absinthe helper to send any response cookies present in the context.
  To be used as a `before_send` hook for `Absinthe.Plug`.
  Response cookies will be set by `CharonAbsinthe.PostSessionChangeMiddleware`.
  """
  @spec send_context_cookies(Plug.Conn.t(), Absinthe.Blueprint.t()) :: Plug.Conn.t()
  def send_context_cookies(
        conn,
        _blueprint = %{execution: %{context: %{@resp_cookies => resp_cookies}}}
      ) do
    %{conn | resp_cookies: Map.merge(conn.resp_cookies, resp_cookies)}
  end

  def send_context_cookies(conn, _), do: conn
end
