defmodule Confex.Providers.ParameterStore do
  require Logger

  def get_parameter(path) do
    resp = ExAws.SSM.get_parameter(path, with_decryption: true) |> ExAws.request()

    case resp do
      {:ok, param} ->
        {:ok,  Kernel.get_in(param, ["Parameter", "Value"])}
      {:error, err} ->
        "ParameterStore error:\n #{inspect(elem(err,2))}"
          |> Logger.error([module: __MODULE__])
        :error
    end
  end
end