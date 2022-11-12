defmodule CharonAbsinthe.PostSessionChangeMiddleware do
  @moduledoc """
  Absinthe middleware to update the resolution after a session is created, refreshed or dropped.
  Transfers `resolution.value.resp_cookies` to resolution.
  """
  @behaviour Absinthe.Middleware
  alias CharonAbsinthe.Internal
  use Internal.Constants

  @impl true
  def call(resolution = %{value: %{resp_cookies: resp_cookies}}, _config) do
    Internal.merge_context(resolution, %{@resp_cookies => resp_cookies})
  end

  def call(resolution, _config), do: resolution
end
