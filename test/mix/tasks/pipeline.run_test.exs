defmodule Mix.Tasks.Pipeline.RunTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    Mix.Task.clear()
    :ok
  end

  test "prints summary and JSON for successful rows" do
    path = temp_path("users.json")

    File.write!(
      path,
      ~s([{"external_id":"user-1","name":"  Ada  Lovelace ","email":" ADA@EXAMPLE.COM "}])
    )

    output =
      capture_io(fn ->
        Mix.Tasks.Pipeline.Run.run(["user_ingest", path, "--no-persist-logs"])
      end)

    assert output =~ "pipeline=user_ingest rows=1 ok=1 error=0"
    assert output =~ "\"status\":\"ok\""
    assert output =~ "\"email\":\"ada@example.com\""
  end

  test "does not crash when a row has tuple error reason" do
    path = temp_path("orders.csv")

    File.write!(
      path,
      """
      order_id,user_id,amount_cents,currency
      ord-1,usr-1,0,usd
      """
    )

    output =
      capture_io(fn ->
        Mix.Tasks.Pipeline.Run.run(["order_ingest", path, "--no-persist-logs"])
      end)

    assert output =~ "pipeline=order_ingest rows=1 ok=0 error=1"
    assert output =~ "\"status\":\"error\""
    assert output =~ "{:validate_amount, {:invalid_positive_integer, :amount_cents}}"
  end

  test "fails with clear error for unknown pipeline name" do
    path = temp_path("users.json")
    File.write!(path, ~s([{"external_id":"user-1","name":"Ada","email":"ada@example.com"}]))

    assert_raise Mix.Error, ~r/unknown_pipeline/, fn ->
      Mix.Tasks.Pipeline.Run.run(["totally_unknown_pipeline", path, "--no-persist-logs"])
    end
  end

  defp temp_path(filename) do
    dir = Path.join(System.tmp_dir!(), "pipeline_bin_mix_task_tests")
    File.mkdir_p!(dir)
    Path.join(dir, "#{System.unique_integer([:positive])}_#{filename}")
  end
end
