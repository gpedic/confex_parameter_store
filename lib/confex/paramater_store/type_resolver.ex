defmodule Confex.ParameterStore.TypeResolver do
  def cast(values, type_info) do
    cast_values =
      values
      |> Keyword.keys()
      |> Enum.map(fn key ->
        {key, cast_value(values[key], type_info[key])}
      end)

    {:ok, cast_values}
  end

  def cast_value(value, nil), do: cast_value(value, :string)

  def cast_value(value, type) do
    {:ok, value} = Confex.Type.cast(value, type)
    value
  end
end
