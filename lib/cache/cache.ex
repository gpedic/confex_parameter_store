defmodule Confex.ParameterStore.Cache do
  @doc """
  This module allows for very simple caching of config values

  In the future to allow for change of config values while the systems are
  running we might want to either allow wiping the cache or set a timeout
  on config settings so they don't stay here forever once written
  """
  use GenServer


  # Public interface

  def start_link() do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def reset() do
    GenServer.call(__MODULE__, {:reset})
  end

  def exists?(key) do
    GenServer.call(__MODULE__, {:exists, key})
  end

  # Server (callbacks)

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    {:reply, value, Map.put(state, key, value)}
  end

  @impl true
  def handle_call({:reset}, _from, _state) do
    {:reply, :ok, %{}}
  end

  @impl true
  def handle_call({:exists, key}, _from, state) do
    {:reply, Map.has_key?(state, key), state}
  end
end