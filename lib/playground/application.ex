defmodule Playground.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require OpenTelemetry.Tracer, as: Tracer

  @impl true
  def start(_type, _args) do
    children = [
      {Playground.PeriodicWorker,
       {fn ->
          Tracer.with_span "Random Task" do
            IO.puts("Task Started")
            Process.sleep(5_000)
            IO.puts("Task Ended")
          end
        end, [schedule: 1_000]}},
      PingServer,
      PongServer
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Playground.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
