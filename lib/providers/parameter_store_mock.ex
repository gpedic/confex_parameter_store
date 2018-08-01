defmodule Confex.Providers.ParameterStoreMock do
  def get_parameter(path) do
    {:ok, path}
  end
end