defmodule PongServer do
  use GenServer
  require OpenTelemetry.Tracer, as: Tracer

  # API

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def send_pong() do
    GenServer.call(__MODULE__, with_trace_data(:pong, "pong"))
  end

  def spike() do
    GenServer.cast(__MODULE__, with_trace_data(:spike, "spike"))
  end

  # GenServer callbacks

  def init(nil) do
    {:ok, []}
  end

  def handle_call({:pong, trace_data}, _from, state) do
    fn ->
      IO.puts("PONG")
      Process.sleep(3_000)
      {:reply, "Received pong", state}
    end
    |> attach_trace(trace_data)
  end

  def handle_cast({:spike, trace_data}, state) do
    fn ->
      Process.sleep(3_000)
      PingServer.send_ping()
      {:noreply, state}
    end
    |> link_trace(trace_data)
  end

  defp with_trace_data(msg, span_name) do
    span = Tracer.start_span(span_name)
    ctx = OpenTelemetry.Ctx.get_current() |> IO.inspect(label: "Ctx.get_current()")
    OpenTelemetry.Tracer.current_span_ctx()

    {msg, {span, ctx}}
  end

  defp attach_trace(fun, {span, ctx}) do
    OpenTelemetry.Ctx.attach(ctx)
    OpenTelemetry.Tracer.set_current_span(span)
    return = fun.()
    OpenTelemetry.Tracer.end_span(span)

    return
  end

  defp link_trace(fun, {span, ctx}) do
    link = OpenTelemetry.link(ctx)
    OpenTelemetry.Tracer.set_current_span(span)
    OpenTelemetry.Tracer.set_attributes(links: [link])
    return = fun.()
    OpenTelemetry.Tracer.end_span(span)

    return
  end
end
