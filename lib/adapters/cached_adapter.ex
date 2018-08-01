defmodule Confex.CachedAdapter do
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Confex.Adapter
      @otp_app Keyword.fetch!(opts, :otp_app)
      @adapter_config Confex.get_env(@otp_app, __MODULE__)
    end
  end
end