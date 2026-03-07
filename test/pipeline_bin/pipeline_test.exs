defmodule PipelineBin.PipelineTest do
  use ExUnit.Case, async: true

  alias PipelineBin.Pipeline

  test "returns step-specific error when a step fails" do
    pipeline =
      Pipeline.new(:failing_pipeline)
      |> Pipeline.add_step(:validate, fn data, _ctx ->
        if Map.has_key?(data, :id), do: {:ok, data}, else: {:error, :missing_id}
      end)
      |> Pipeline.add_step(:unreachable, fn _data, _ctx ->
        flunk("this step should not be executed")
      end)

    assert {:error, {:validate, :missing_id}} = Pipeline.run(pipeline, %{name: "no id"})
  end
end
