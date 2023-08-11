defmodule OpentelemetryTest do
  use ExUnit.Case
  doctest Opentelemetry

  test "greets the world" do
    assert Opentelemetry.hello() == :world
  end
end
