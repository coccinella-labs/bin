defmodule PipelineBin.Workers.RunPipelineWorker do
  @moduledoc """
  Oban worker to run a named pipeline over an input file.

  Expects args:
  - `pipeline` (string)
  - `path` (string)
  - optional `log_path` (string)
  - optional `run_id` (string)
  """

  use Oban.Worker, queue: :pipelines, max_attempts: 5

  alias PipelineBin.Adapters.FileInput
  alias PipelineBin.Pipelines

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"pipeline" => pipeline, "path" => path} = args}) do
    registry = Pipelines.registry()

    context =
      %{}
      |> put_if_present(:log_path, args["log_path"])
      |> put_if_present(:run_id, args["run_id"])

    with {:ok, pipeline_atom} <- Pipelines.resolve_name(registry, pipeline),
         {:ok, _results} <- FileInput.run_file(registry, pipeline_atom, path, context) do
      :ok
    else
      {:error, reason} -> {:error, inspect(reason)}
    end
  end

  defp put_if_present(map, _key, nil), do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)
end
