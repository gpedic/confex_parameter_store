defmodule Confex.ParameterStoreMock do
  @behaviour Confex.ParameterStore.Provider
  def get_parameter(path) do
    {:ok, path}
  end
end
