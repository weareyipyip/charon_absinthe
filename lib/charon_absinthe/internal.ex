defmodule CharonAbsinthe.Internal do
  @moduledoc false

  @doc """
  Merge a map into an `%Absinthe.Resolution{}` context.
  """
  def merge_context(resolution = %{context: context}, map) do
    %{resolution | context: Map.merge(context, map)}
  end

  @doc """
  Set an `%Absinthe.Resolution{}` state to `:resolved`.
  """
  def resolve_resolution(resolution), do: %{resolution | state: :resolved}
end
