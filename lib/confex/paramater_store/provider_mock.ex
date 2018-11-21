defmodule Confex.ParameterStoreMock do
  @behaviour Confex.ParameterStore.Provider
  def get_parameter(path) do
    {:ok, path}
  end

  def get_parameters_by_path(path) do
    {:ok, [example: path]}
  end
end
