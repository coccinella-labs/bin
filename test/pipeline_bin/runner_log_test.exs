defmodule PipelineBin.RunnerLogTest do
  use ExUnit.Case, async: false

  alias PipelineBin.Pipelines
  alias PipelineBin.Runner

  test "persists success and failure logs per step" do
    log_path = temp_log_path()
    registry = Pipelines.registry()

    ok_input = %{external_id: "user-1", name: "Ada Lovelace", email: "ada@example.com"}
    bad_input = %{external_id: "user-2", name: "Grace Hopper", email: "invalid"}

    assert {:ok, _} =
             Runner.run(registry, :user_ingest, ok_input, %{log_path: log_path, run_id: "run-ok"})

    assert {:error, {:normalize_email, :invalid_email}} =
             Runner.run(registry, :user_ingest, bad_input, %{log_path: log_path, run_id: "run-fail"})

    lines =
      log_path
      |> File.read!()
      |> String.split("\n", trim: true)
      |> Enum.map(&JSON.decode!/1)

    assert Enum.any?(lines, fn line ->
             line["run_id"] == "run-ok" and line["step"] == "normalize_email" and line["status"] == "ok"
           end)

    assert Enum.any?(lines, fn line ->
             line["run_id"] == "run-fail" and line["step"] == "normalize_email" and
               line["status"] == "error"
           end)
  end

  defp temp_log_path do
    dir = Path.join(System.tmp_dir!(), "pipeline_bin_logs")
    File.mkdir_p!(dir)
    Path.join(dir, "runner_#{System.unique_integer([:positive])}.log")
  end
end
