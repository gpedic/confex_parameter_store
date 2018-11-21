defmodule Confex.Adapters.ParameterStoreTest do
  use ExUnit.Case

  @tag :external
  test "fetch a path from the parameter store" do
    ExAws.SSM.put_parameter("/app/token", :string, "test1234") |> ExAws.request!()
    System.put_env("STORE_PARAM", "parameter:/app/token")
    assert {:ok, "test1234"} == Confex.Adapters.ParameterStore.fetch_value("STORE_PARAM")
  end

  @tag :external
  test "fetch non existing value" do
    System.put_env("MISSING_PARAM", "parameter:/does/not/exist")
    assert :error == Confex.Adapters.ParameterStore.fetch_value("MISSING_PARAM")
  end

  test "fetch a non parameter store value" do
    System.put_env("REGULAR_PARAM", "regular_env_value")

    assert {:ok, "regular_env_value"} ==
             Confex.Adapters.ParameterStore.fetch_value("REGULAR_PARAM")
  end

  test "fetch a non existing ENV" do
    assert :error == Confex.Adapters.ParameterStore.fetch_value("NOT_EXISTS")
  end
end
