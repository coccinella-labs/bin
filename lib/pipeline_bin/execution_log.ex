defmodule PipelineBin.ExecutionLog do
  @moduledoc """
  Persists pipeline step execution logs as newline-delimited JSON.
  """

  @default_log_path "var/pipeline_execution.log"

  @spec append(atom(), [map()], map()) :: :ok | {:error, any()}
  def append(pipeline_name, traces, context) when is_atom(pipeline_name) and is_list(traces) do
    log_path = Map.get(context, :log_path, @default_log_path)
    run_id = Map.get(context, :run_id, default_run_id())
    input_id = Map.get(context, :input_id)

    entries =
      Enum.map(traces, fn trace ->
        %{
          run_id: run_id,
          pipeline: pipeline_name,
          input_id: input_id,
          step: trace.step,
          status: trace.status,
          started_at: DateTime.to_iso8601(trace.started_at),
          finished_at: DateTime.to_iso8601(trace.finished_at),
          duration_us: trace.duration_us,
          reason: normalize_reason(trace.reason)
        }
      end)

    with :ok <- ensure_parent_dir(log_path),
         {:ok, encoded} <- encode_entries(entries),
         :ok <- File.write(log_path, encoded, [:append]) do
      :ok
    end
  end

  defp ensure_parent_dir(path) do
    path |> Path.dirname() |> File.mkdir_p()
  end

  defp encode_entries(entries) do
    encoded =
      entries
      |> Enum.map_join("", fn entry -> JSON.encode!(entry) <> "\n" end)

    {:ok, encoded}
  rescue
    error -> {:error, error}
  end

  defp default_run_id do
    DateTime.utc_now()
    |> DateTime.to_unix(:microsecond)
    |> Integer.to_string()
  end

  defp normalize_reason(nil), do: nil
  defp normalize_reason(reason), do: inspect(reason)
end
