defmodule Confex.ParameterStore.ProviderImpl do
  @behaviour Confex.ParameterStore.Provider
  @path_regex ~r/^.*\/(.+)$/
  require Logger

  def get_parameter(path) do
    resp = ExAws.SSM.get_parameter(path, with_decryption: true) |> ExAws.request()

    case resp do
      {:ok, param} ->
        {:ok, Kernel.get_in(param, ["Parameter", "Value"])}

      {:error, err} ->
        "ParameterStore error:\n #{inspect(elem(err, 2))}"
        |> Logger.error(module: __MODULE__)

        :error
    end
  end

  def get_parameters_by_path(path) do
    resp =
      ExAws.SSM.get_parameters_by_path(path, with_decryption: true, recursive: true)
      |> ExAws.request()

    case resp do
      {:ok, params} ->
        params
        |> Map.get("Parameters")
        |> Enum.map(fn param -> parse_path_param(param) end)
        |> (&{:ok, &1}).()

      _ ->
        :error
    end
  end

  defp parse_path_param(param) do
    {parse_param_name_atom(param["Name"]), param["Value"]}
  end

  defp parse_param_name_atom(param_path) do
    Regex.run(@path_regex, param_path) |> List.last() |> String.to_atom()
  end
end
