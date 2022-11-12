defmodule CharonAbsinthe.ConfigTest do
  use ExUnit.Case, async: true
  alias Charon.Internal.ConfigTest

  @configurations %{
    CharonAbsinthe.Config => %{
      access_token_pipeline: :required,
      refresh_token_pipeline: :required,
      auth_error_handler: :required
    }
  }

  describe "Configs" do
    test "default optional values" do
      ConfigTest.test_optional(@configurations)
    end

    test "require required values" do
      ConfigTest.test_required(@configurations)
    end
  end
end
