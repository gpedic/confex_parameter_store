defmodule Confex.ParameterStore.ProviderImpl do
  @behaviour Confex.ParameterStore.Provider
  @path_regex ~r/^.*\/(.+)$/
  require Logger

  def get_parameter(path) do
    ExAws.SSM.get_parameter(path, with_decryption: true)
    |> ExAws.request()
    |> parse_resp()
  end

  def get_parameters_by_path(path) do
    ExAws.SSM.get_parameters_by_path(path, with_decryption: true, recursive: true)
    |> ExAws.request()
    |> parse_resp()
  end

  defp parse_resp({:ok, %{"Parameter" => param}}) do
    {:ok, Map.get(param, "Value")}
  end

  defp parse_resp({:ok, %{"Parameters" => params}}) do
    params
    |> Enum.map(fn param -> parse_path_param(param) end)
    |> (&{:ok, &1}).()
  end

  defp parse_resp({:error, err}) do
    Logger.error("Error requesting parameter: #{inspect(elem(err, 2))}")
    :error
  end

  defp parse_path_param(param) do
    {parse_param_name_atom(param["Name"]), param["Value"]}
  end

  defp parse_param_name_atom(param_path) do
    Regex.run(@path_regex, param_path)
    |> List.last()
    |> String.to_atom()
  end
end
