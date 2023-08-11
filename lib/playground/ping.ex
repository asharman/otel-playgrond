defmodule PingServer do
  use GenServer
  require OpenTelemetry.Tracer, as: Tracer

  # API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send_ping() do
    GenServer.call(__MODULE__, :ping)
  end

  # GenServer callbacks

  def init(nil) do
    {:ok, []}
  end

  def handle_call(:ping, _from, state) do
    Tracer.with_span "ping" do
      IO.puts("PING")
      Process.sleep(1_000)
      PongServer.spike()
      {:reply, "Received ping", state}
    end
  end
end
