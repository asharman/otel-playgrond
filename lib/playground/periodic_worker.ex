defmodule Playground.PeriodicWorker do
  use GenServer
  require OpenTelemetry.Tracer, as: Tracer
  require OpenTelemetry.Ctx, as: Ctx

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init({task, opts}) do
    schedule = Keyword.get(opts, :schedule, 1_000)
    {:ok, %{schedule: schedule, task: task, pid: self()}, {:continue, :run_task}}
  end

  # span_ctx = OpenTelemetry.Tracer.start_span(:child)
  # ctx = OpenTelemetry.Ctx.get_current()

  # task = Task.async(fn ->
  #                       OpenTelemetry.Ctx.attach(ctx)
  #                       OpenTelemetry.Tracer.set_current_span(span_ctx)
  #                       # do work here

  #                       # end span here
  #                       OpenTelemetry.Tracer.end_span(span_ctx)
  #                   end)

  # _ = Task.await(task)
  # Populate with something

  # Task
  # 1. Get whatever span context is starting the Task
  # 2. Create a new Span that will be executed in the Task
  # 3. Inside the Task, attach the Task Spawner's context as the current context
  # 4. Set the current span to the created context that was passed in (closure)
  # 5. After work is done, close the child span manually

  # Attributes
  # Module Name
  # Function Name
  # Process PID

  def handle_continue(:run_task, state) do
    Tracer.with_span "Handle Continue" do
      span_ctx_1 = Tracer.start_span("Periodic Job Outer")
      ctx_1 = OpenTelemetry.Ctx.get_current()

      Task.async(fn ->
        OpenTelemetry.Ctx.attach(ctx_1)
        OpenTelemetry.Tracer.set_current_span(span_ctx_1)
        Tracer.set_attributes([{:pid, inspect(self())}])

        Process.sleep(2_000)

        span_ctx_2 = Tracer.start_span("Periodic Job Inner")
        ctx_2 = OpenTelemetry.Ctx.get_current()

        Task.start(fn ->
          OpenTelemetry.Ctx.attach(ctx_2)
          OpenTelemetry.Tracer.set_current_span(span_ctx_2)
          Tracer.set_attributes([{:pid, inspect(self())}])
          # DO WORK
          Process.sleep(1_000)
          state.task.()
          schedule_task(state)

          # END SPAN
          OpenTelemetry.Tracer.end_span(span_ctx_2)
        end)

        # END SPAN
        OpenTelemetry.Tracer.end_span(span_ctx_1)
      end)
      |> Task.await()

      Process.sleep(4_000)

      {:noreply, state}
    end
  end

  # def handle_continue(:run_task, state) do
  #   Tracer.with_span "Periodic Job" do
  #     Task.start(fn ->
  #       state.task.()
  #       schedule_task(state)
  #     end)
  #   end

  #   {:noreply, state}
  # end

  def handle_info(:timer, state) do
    {:noreply, state, {:continue, :run_task}}
  end

  defp schedule_task(state) do
    Process.send_after(state.pid, :timer, state.schedule)
  end
end
