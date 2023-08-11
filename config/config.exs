import Config

config :opentelemetry,
  span_process: :batch,
  traces_exporter: :otlp

# traces_exporter: {:otel_exporter_stdout, []}

config :opentelemetry_exporter,
  otlp_protocol: :http_protobuf,
  otlp_endpoint: "http://0.0.0.0:4318"
