defmodule Playground.PeriodicWorker do
  use GenServer
  require OpenTelemetry.Tracer, as: Tracer

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({task, opts}) do
    schedule = Keyword.get(opts, :schedule, 1_000)
    {:ok, %{schedule: schedule, task: task, pid: self()}, {:continue, :run_task}}
  end

  def handle_continue(:run_task, state) do
    Tracer.with_span "Periodic Job" do
      state.task.()
    end

    schedule_task(state)
    {:noreply, state}
  end

  def handle_info(:timer, state) do
    {:noreply, state, {:continue, :run_task}}
  end

  defp schedule_task(state) do
    Process.send_after(state.pid, :timer, state.schedule)
  end
end
