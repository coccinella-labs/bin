defmodule Mix.Tasks.Pipeline.Run do
  @shortdoc "Run a named pipeline against a JSON or CSV file"
  @moduledoc """
  Runs a named pipeline over every row from a JSON/CSV input file.

  ## Usage

      mix pipeline.run PIPELINE_NAME INPUT_PATH [--log-path path] [--run-id id] [--no-persist-logs]
  """

  use Mix.Task

  alias PipelineBin.Adapters.FileInput
  alias PipelineBin.Pipelines

  @impl true
  def run(args) do
    Mix.Task.run("app.start")

    {opts, positional, invalid} =
      OptionParser.parse(args,
        strict: [log_path: :string, run_id: :string, persist_logs: :boolean],
        aliases: [l: :log_path]
      )

    if invalid != [] do
      Mix.raise("Invalid options: #{inspect(invalid)}")
    end

    case positional do
      [pipeline_name, input_path] ->
        run_pipeline(pipeline_name, input_path, opts)

      _ ->
        Mix.shell().error("Usage: mix pipeline.run PIPELINE_NAME INPUT_PATH [--log-path path] [--run-id id] [--no-persist-logs]")
    end
  end

  defp run_pipeline(pipeline_name, input_path, opts) do
    registry = Pipelines.registry()
    context = build_context(opts)

    with {:ok, pipeline_atom} <- Pipelines.resolve_name(registry, pipeline_name),
         {:ok, results} <- FileInput.run_file(registry, pipeline_atom, input_path, context) do
      {ok_count, error_count} = count_results(results)
      serialized_results = Enum.map(results, &serialize_result/1)
      Mix.shell().info("pipeline=#{pipeline_name} rows=#{length(results)} ok=#{ok_count} error=#{error_count}")
      Mix.shell().info(JSON.encode!(serialized_results))
    else
      {:error, reason} ->
        Mix.raise("Pipeline run failed: #{inspect(reason)}")
    end
  end

  defp build_context(opts) do
    %{}
    |> put_if_present(:log_path, opts[:log_path])
    |> put_if_present(:run_id, opts[:run_id])
    |> put_if_present(:persist_logs?, opts[:persist_logs])
  end

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp count_results(results) do
    Enum.reduce(results, {0, 0}, fn result, {ok_count, error_count} ->
      case result.status do
        :ok -> {ok_count + 1, error_count}
        :error -> {ok_count, error_count + 1}
      end
    end)
  end

  defp serialize_result(%{index: index, status: :ok, output: output}) do
    %{
      index: index,
      status: "ok",
      output: serialize_value(output)
    }
  end

  defp serialize_result(%{index: index, status: :error, reason: reason}) do
    %{
      index: index,
      status: "error",
      reason: inspect(reason)
    }
  end

  defp serialize_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp serialize_value(value) when is_map(value), do: Map.new(value, fn {k, v} -> {k, serialize_value(v)} end)
  defp serialize_value(value) when is_list(value), do: Enum.map(value, &serialize_value/1)
  defp serialize_value(value), do: value
end
