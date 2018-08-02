defmodule Confex.ParameterStore do
  use Application
  import Supervisor.Spec

  @moduledoc """
  Documentation for ConfexParameterStore.
  """

  def start(_type, _args) do
    config = Confex.get_env(:confex, __MODULE__, [cache: Confex.ParameterStore.Cache]) |> IO.inspect

    children = [
      worker(config[:cache], [])
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
