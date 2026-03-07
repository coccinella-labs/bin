defmodule PipelineBin.Broadway.RunnerTest do
  use ExUnit.Case, async: false

  alias PipelineBin.Broadway.Runner
  alias PipelineBin.Pipelines

  test "runs batch rows and preserves ok/error statuses" do
    rows = [
      %{order_id: "ord-1", user_id: "usr-1", amount_cents: 2500, currency: "usd"},
      %{order_id: "ord-2", user_id: "usr-2", amount_cents: 0, currency: "usd"}
    ]

    results =
      Runner.run_batch(Pipelines.registry(), :order_ingest, rows, %{persist_logs?: false},
        processor_concurrency: 2
      )

    assert length(results) == 2
    assert Enum.at(results, 0).status == :ok
    assert Enum.at(results, 1).status == :error
    assert Enum.at(results, 1).reason == {:validate_amount, {:invalid_positive_integer, :amount_cents}}
  end
end
