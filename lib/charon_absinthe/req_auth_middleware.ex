defmodule CharonAbsinthe.ReqAuthMiddleware do
  @moduledoc """
  Absinthe middleware to require a valid access token.
  Can be used if the context was hydrated by `CharonAbsinthe.HydrateContextPlug`.
  """
  @behaviour Absinthe.Middleware
  use Charon.Internal.Constants
  alias CharonAbsinthe.Internal

  @impl true
  def call(resolution = %{context: %{@auth_error => error}}, config) do
    mod_config = CharonAbsinthe.get_module_config(config)
    mod_config.auth_error_handler.(resolution, error) |> Internal.resolve_resolution()
  end

  def call(resolution, _config), do: resolution
end
