defmodule PipelineBin.Runner do
  @moduledoc """
  Runs named pipelines from a local registry map.
  """

  alias PipelineBin.ExecutionLog
  alias PipelineBin.Pipeline

  @spec run(map(), atom(), any(), map()) :: {:ok, any()} | {:error, any()}
  def run(registry, pipeline_name, input, context \\ %{})
      when is_map(registry) and is_atom(pipeline_name) and is_map(context) do
    case Map.fetch(registry, pipeline_name) do
      {:ok, %Pipeline{} = pipeline} ->
        case Pipeline.run_with_trace(pipeline, input, context) do
          {:ok, output, traces} ->
            _ = maybe_persist_logs(pipeline_name, traces, context)
            {:ok, output}

          {:error, reason, traces} ->
            _ = maybe_persist_logs(pipeline_name, traces, context)
            {:error, reason}
        end

      :error -> {:error, {:unknown_pipeline, pipeline_name}}
    end
  end

  defp maybe_persist_logs(pipeline_name, traces, context) do
    if Map.get(context, :persist_logs?, true) do
      ExecutionLog.append(pipeline_name, traces, context)
    else
      :ok
    end
  end
end
