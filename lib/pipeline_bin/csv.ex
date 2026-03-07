defmodule PipelineBin.CSV do
  @moduledoc """
  CSV parsing helpers powered by NimbleCSV.
  """

  NimbleCSV.define(Parser, separator: ",", escape: "\"")

  @spec parse_file(String.t()) :: {:ok, [map()]} | {:error, any()}
  def parse_file(path) when is_binary(path) do
    with true <- File.exists?(path) or {:error, :enoent},
         {:ok, parsed_rows} <- parse_rows(path),
         {:ok, [headers | data_rows]} <- ensure_header(parsed_rows) do
      rows =
        Enum.map(data_rows, fn values ->
          headers
          |> Enum.zip(values)
          |> Enum.into(%{}, fn {key, value} -> {to_existing_or_string(key), cast_value(value)} end)
        end)

      {:ok, rows}
    else
      {:ok, []} -> {:error, :empty_csv}
      false -> {:error, :enoent}
      error -> error
    end
  rescue
    error -> {:error, error}
  end

  defp parse_rows(path) do
    rows =
      path
      |> File.stream!()
      |> Parser.parse_stream(skip_headers: false)
      |> Enum.to_list()

    {:ok, rows}
  end

  defp ensure_header([]), do: {:ok, []}
  defp ensure_header(rows), do: {:ok, rows}

  defp cast_value(value) do
    trimmed = String.trim(value)

    case Integer.parse(trimmed) do
      {number, ""} -> number
      _ -> trimmed
    end
  end

  defp to_existing_or_string(key) do
    key = String.trim(key)

    try do
      String.to_existing_atom(key)
    rescue
      ArgumentError -> key
    end
  end
end
