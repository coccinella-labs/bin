defmodule PipelineBin.PipelinesTest do
  use ExUnit.Case, async: true

  alias PipelineBin.Pipelines

  test "resolve_name resolves known string names without creating atoms" do
    registry = Pipelines.registry()

    assert {:ok, :user_ingest} = Pipelines.resolve_name(registry, "user_ingest")
    assert {:error, {:unknown_pipeline, "not_real"}} = Pipelines.resolve_name(registry, "not_real")
  end
end
