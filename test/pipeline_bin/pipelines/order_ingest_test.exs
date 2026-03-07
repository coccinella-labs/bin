defmodule PipelineBin.Pipelines.OrderIngestTest do
  use ExUnit.Case, async: true

  alias PipelineBin.Pipelines
  alias PipelineBin.Runner

  test "normalizes inbound order data" do
    registry = Pipelines.registry()
    ingested_at = ~U[2026-03-08 02:00:00Z]

    input = %{
      order_id: "ord-001",
      user_id: "usr-001",
      amount_cents: 1500,
      currency: " usd "
    }

    assert {:ok,
            %{
              order_id: "ord-001",
              user_id: "usr-001",
              amount_cents: 1500,
              currency: "USD",
              ingested_at: ~U[2026-03-08 02:00:00Z]
            }} =
             Runner.run(registry, :order_ingest, input, %{ingested_at: ingested_at, persist_logs?: false})
  end

  test "fails when amount is not a positive integer" do
    registry = Pipelines.registry()

    input = %{
      order_id: "ord-001",
      user_id: "usr-001",
      amount_cents: 0,
      currency: "USD"
    }

    assert {:error, {:validate_amount, {:invalid_positive_integer, :amount_cents}}} =
             Runner.run(registry, :order_ingest, input, %{persist_logs?: false})
  end
end
