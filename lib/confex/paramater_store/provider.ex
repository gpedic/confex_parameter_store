defmodule Confex.ParameterStore.Provider do
  @doc "Fetches a value"
  @callback get_parameter(binary()) :: {:ok, binary()} | :error
end
