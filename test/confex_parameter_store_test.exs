defmodule Confex.Adapters.ParameterStoreTest do
  use ExUnit.Case

  setup context do
    if params = context[:create_params] do
      params
      |> Enum.each(fn param ->
        apply(ExAws.SSM, :put_parameter, param)
        |> ExAws.request!()
      end)

      unless context[:no_cleanup] do
        on_exit(fn ->
          params
          |> Enum.map(&hd/1)
          |> ExAws.SSM.delete_parameters()
          |> ExAws.request!()
        end)
      end
    end

    :ok
  end

  @tag :external
  @tag create_params: [
         ["/myapp1/token", :string, "test1234"]
       ]
  test "fetch a path from the parameter store" do
    System.put_env("STORE_PARAM", "parameter:/myapp1/token")
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

  describe "get_parameter_by_path" do
    @tag create_params: [
           ["/myapp1/test/user", :string, "test"],
           ["/myapp1/test/pass", :string, "test1234"]
         ]
    @tag :external
    test "get_parameters_by_path" do
      Application.put_env(
        :myapp1,
        :info,
        {{:via, Confex.Adapters.ParameterStore}, "MYAPP1_PARAMS"}
      )

      System.put_env("MYAPP1_PARAMS", "parameters_by_path:/myapp1/")

      {:ok, resp} = Confex.fetch_env(:myapp1, :info)
      assert Keyword.get(resp, :user) === "test"
      assert Keyword.get(resp, :pass) === "test1234"
    end

    @tag create_params: [
           ["/myapp2/test/user", :string, "test"],
           ["/myapp2/info/fraction", :string, "1.11"],
           ["/myapp2/info/enabled", :string, "true"],
           ["/myapp2/info/port", :string, "5432"],
           ["/myapp2/info/timeout", :string, "infinity"],
           ["/myapp2/info/module", :string, "Example.Name"],
           ["/myapp2/info/listing", :string, "1,2,3,4"]
         ]
    @tag :external
    test "get_parameters_by_path with type casting" do
      custom_type =
        {Confex.ParameterStore.TypeResolver, :cast,
         [
           [
             port: :integer,
             enabled: :boolean,
             timeout: :atom,
             fraction: :float,
             module: :module,
             listing: :list
           ]
         ]}

      Application.put_env(
        :myapp2,
        :info,
        {{:via, Confex.Adapters.ParameterStore}, custom_type, "MYAPP2_PARAMS"}
      )

      System.put_env("MYAPP2_PARAMS", "parameters_by_path:/myapp2/")

      {:ok, resp} = Confex.fetch_env(:myapp2, :info)
      assert Keyword.get(resp, :user) === "test"
      assert Keyword.get(resp, :fraction) === 1.11
      assert Keyword.get(resp, :enabled) === true
      assert Keyword.get(resp, :port) === 5432
      assert Keyword.get(resp, :timeout) === :infinity
      assert Keyword.get(resp, :module) === Example.Name
      assert Keyword.get(resp, :listing) === ["1", "2", "3", "4"]
    end
  end
end
