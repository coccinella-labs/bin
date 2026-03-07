defmodule PipelineBin.Broadway.Runner do
  @moduledoc """
  Broadway-based concurrent runner for in-memory row batches.

  This module is intentionally opt-in; it is not started in the application tree.
  """

  use Broadway

  alias Broadway.Message
  alias PipelineBin.Runner, as: PipelineRunner

  @spec run_batch(map(), atom(), [map()], map(), keyword()) :: [map()]
  def run_batch(registry, pipeline_name, rows, context \\ %{}, opts \\ [])
      when is_map(registry) and is_atom(pipeline_name) and is_list(rows) and is_map(context) do
    caller = self()
    total = length(rows)
    name = Keyword.get(opts, :name, Module.concat(__MODULE__, "Run#{System.unique_integer([:positive])}"))
    timeout_ms = Keyword.get(opts, :timeout_ms, 30_000)

    start_opts = [
      name: name,
      rows: rows,
      registry: registry,
      pipeline_name: pipeline_name,
      context: context,
      caller: caller,
      producer_concurrency: Keyword.get(opts, :producer_concurrency, 1),
      processor_concurrency: Keyword.get(opts, :processor_concurrency, System.schedulers_online())
    ]

    {:ok, pid} = start_link(start_opts)

    results =
      1..total
      |> Enum.map(fn _ -> await_result(timeout_ms) end)
      |> Enum.sort_by(& &1.index)

    _ = GenServer.stop(pid, :normal, timeout_ms)
    results
  end

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: opts[:name] || __MODULE__,
      producer: [
        module: {PipelineBin.Broadway.Runner.Producer, opts},
        concurrency: Keyword.get(opts, :producer_concurrency, 1)
      ],
      processors: [
        default: [
          concurrency: Keyword.get(opts, :processor_concurrency, System.schedulers_online())
        ]
      ]
    )
  end

  @impl true
  def handle_message(_processor, %Message{data: row, metadata: metadata} = message, _context) do
    registry = metadata.registry
    pipeline_name = metadata.pipeline_name
    context = Map.get(metadata, :context, %{})
    caller = metadata.caller
    index = metadata.index

    result = PipelineRunner.run(registry, pipeline_name, row, Map.put_new(context, :input_id, "row-#{index}"))
    send(caller, {:pipeline_result, index, result})

    message
  end

  defp await_result(timeout_ms) do
    receive do
      {:pipeline_result, index, {:ok, output}} ->
        %{index: index, status: :ok, output: output}

      {:pipeline_result, index, {:error, reason}} ->
        %{index: index, status: :error, reason: reason}
    after
      timeout_ms ->
        %{index: -1, status: :error, reason: :timeout}
    end
  end
end
