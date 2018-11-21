defmodule Confex.ParameterStore.Provider do
  @doc "Fetches a value"
  @callback get_parameter(binary()) :: {:ok, binary()} | :error

  @doc "Fetches values based on the path"
  @callback get_parameters_by_path(binary()) :: {:ok, list()} | :error
end
