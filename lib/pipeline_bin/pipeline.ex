defmodule PipelineBin.Pipeline do
  @moduledoc """
  A simple in-memory data pipeline.

  Each step is a function with arity 2: `(data, context)`.
  It must return either `{:ok, transformed_data}` or `{:error, reason}`.
  """

  defstruct [:name, steps: []]

  @type step_result :: {:ok, any()} | {:error, any()}
  @type step_fun :: (any(), map() -> step_result)
  @type step :: {atom(), step_fun()}
  @type step_trace :: %{
          step: atom(),
          status: :ok | :error,
          started_at: DateTime.t(),
          finished_at: DateTime.t(),
          duration_us: non_neg_integer(),
          reason: any() | nil
        }
  @type t :: %__MODULE__{name: atom(), steps: [step()]}

  @spec new(atom()) :: t()
  def new(name) when is_atom(name), do: %__MODULE__{name: name}

  @spec add_step(t(), atom(), step_fun()) :: t()
  def add_step(%__MODULE__{} = pipeline, name, fun) when is_atom(name) and is_function(fun, 2) do
    %{pipeline | steps: pipeline.steps ++ [{name, fun}]}
  end

  @spec run(t(), any(), map()) :: {:ok, any()} | {:error, {atom(), any()}}
  def run(%__MODULE__{} = pipeline, input, context \\ %{}) when is_map(context) do
    case run_with_trace(pipeline, input, context) do
      {:ok, output, _trace} -> {:ok, output}
      {:error, reason, _trace} -> {:error, reason}
    end
  end

  @spec run_with_trace(t(), any(), map()) ::
          {:ok, any(), [step_trace()]} | {:error, {atom(), any()}, [step_trace()]}
  def run_with_trace(%__MODULE__{} = pipeline, input, context \\ %{}) when is_map(context) do
    do_run_with_trace(pipeline.steps, input, context, [])
  end

  defp do_run_with_trace([], data, _context, traces), do: {:ok, data, Enum.reverse(traces)}

  defp do_run_with_trace([{name, step_fun} | rest], data, context, traces) do
    started_at = DateTime.utc_now()
    started_mono = System.monotonic_time(:microsecond)

    case step_fun.(data, context) do
      {:ok, new_data} ->
        finished_at = DateTime.utc_now()
        duration_us = System.monotonic_time(:microsecond) - started_mono

        trace = %{
          step: name,
          status: :ok,
          started_at: started_at,
          finished_at: finished_at,
          duration_us: duration_us,
          reason: nil
        }

        do_run_with_trace(rest, new_data, context, [trace | traces])

      {:error, reason} ->
        finished_at = DateTime.utc_now()
        duration_us = System.monotonic_time(:microsecond) - started_mono

        trace = %{
          step: name,
          status: :error,
          started_at: started_at,
          finished_at: finished_at,
          duration_us: duration_us,
          reason: reason
        }

        {:error, {name, reason}, Enum.reverse([trace | traces])}
    end
  end
end
