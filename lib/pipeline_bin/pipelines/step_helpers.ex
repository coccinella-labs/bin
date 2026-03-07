defmodule PipelineBin.Pipelines.StepHelpers do
  @moduledoc """
  Reusable step builders for common validation and normalization patterns.
  """

  @type step_result :: {:ok, any()} | {:error, any()}
  @type step_fun :: (any(), map() -> step_result)

  @spec require_fields([atom()]) :: step_fun()
  def require_fields(required_fields) when is_list(required_fields) do
    fn data, _context ->
      missing =
        required_fields
        |> Enum.reject(&present?(Map.get(data, &1)))

      case missing do
        [] -> {:ok, data}
        fields -> {:error, {:missing_fields, fields}}
      end
    end
  end

  @spec trim_and_squish(atom()) :: step_fun()
  def trim_and_squish(field) when is_atom(field) do
    fn data, _context ->
      normalized =
        data
        |> Map.fetch!(field)
        |> String.trim()
        |> String.replace(~r/\s+/, " ")

      {:ok, Map.put(data, field, normalized)}
    end
  end

  @spec normalize_email(atom()) :: step_fun()
  def normalize_email(field) when is_atom(field) do
    fn data, _context ->
      normalized_email =
        data
        |> Map.fetch!(field)
        |> String.trim()
        |> String.downcase()

      if String.contains?(normalized_email, "@") do
        {:ok, Map.put(data, field, normalized_email)}
      else
        {:error, :invalid_email}
      end
    end
  end

  @spec normalize_uppercase(atom()) :: step_fun()
  def normalize_uppercase(field) when is_atom(field) do
    fn data, _context ->
      normalized =
        data
        |> Map.fetch!(field)
        |> String.trim()
        |> String.upcase()

      {:ok, Map.put(data, field, normalized)}
    end
  end

  @spec validate_positive_integer(atom()) :: step_fun()
  def validate_positive_integer(field) when is_atom(field) do
    fn data, _context ->
      value = Map.fetch!(data, field)

      if is_integer(value) and value > 0 do
        {:ok, data}
      else
        {:error, {:invalid_positive_integer, field}}
      end
    end
  end

  @spec stamp_datetime(atom(), atom()) :: step_fun()
  def stamp_datetime(output_field, context_key) when is_atom(output_field) and is_atom(context_key) do
    fn data, context ->
      value = Map.get(context, context_key, DateTime.utc_now())
      {:ok, Map.put(data, output_field, value)}
    end
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(value), do: not is_nil(value)
end
