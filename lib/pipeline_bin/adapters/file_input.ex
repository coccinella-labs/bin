defmodule PipelineBin.Adapters.FileInput do
  @moduledoc """
  Loads JSON/CSV files and runs each row through a named pipeline.
  """

  alias PipelineBin.CSV
  alias PipelineBin.Runner

  @spec run_file(map(), atom(), String.t(), map()) :: {:ok, [map()]} | {:error, any()}
  def run_file(registry, pipeline_name, path, context \\ %{})
      when is_map(registry) and is_atom(pipeline_name) and is_binary(path) and is_map(context) do
    with {:ok, rows} <- load_rows(path),
         {:ok, results} <- run_rows(registry, pipeline_name, rows, context) do
      {:ok, results}
    end
  end

  defp run_rows(registry, pipeline_name, rows, context) do
    results =
      rows
      |> Enum.with_index()
      |> Enum.map(fn {row, index} ->
        row_context =
          context
          |> Map.put_new(:input_id, "row-#{index + 1}")

        case Runner.run(registry, pipeline_name, row, row_context) do
          {:ok, output} -> %{index: index + 1, status: :ok, output: output}
          {:error, reason} -> %{index: index + 1, status: :error, reason: reason}
        end
      end)

    {:ok, results}
  rescue
    error -> {:error, error}
  end

  defp load_rows(path) do
    case Path.extname(path) do
      ".json" -> load_json(path)
      ".csv" -> load_csv(path)
      ext -> {:error, {:unsupported_file_type, ext}}
    end
  end

  defp load_json(path) do
    with {:ok, content} <- File.read(path),
         {:ok, decoded} <- JSON.decode(content),
         {:ok, rows} <- normalize_json_rows(decoded) do
      {:ok, Enum.map(rows, &string_key_map_to_atoms/1)}
    end
  end

  defp normalize_json_rows(decoded) when is_list(decoded), do: {:ok, decoded}
  defp normalize_json_rows(decoded) when is_map(decoded), do: {:ok, [decoded]}
  defp normalize_json_rows(_), do: {:error, :invalid_json_payload}

  defp load_csv(path) do
    CSV.parse_file(path)
  end

  defp string_key_map_to_atoms(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) and is_map(value) ->
        {to_existing_or_string(key), string_key_map_to_atoms(value)}

      {key, value} when is_binary(key) ->
        {to_existing_or_string(key), value}

      {key, value} ->
        {key, value}
    end)
  end

  defp to_existing_or_string(key) do
    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end
end
