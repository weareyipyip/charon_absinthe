defmodule CharonAbsinthe.Internal.Constants do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      @resp_cookies :charon_absinthe_resp_cookies
    end
  end
end
