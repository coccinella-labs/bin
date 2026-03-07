defmodule PipelineBin.Broadway.Runner.Producer do
  @moduledoc false

  use GenStage

  alias Broadway.Message

  @impl true
  def init(opts) do
    rows = Keyword.get(opts, :rows, [])
    registry = Keyword.fetch!(opts, :registry)
    pipeline_name = Keyword.fetch!(opts, :pipeline_name)
    context = Keyword.get(opts, :context, %{})
    caller = Keyword.get(opts, :caller, self())

    events =
      rows
      |> Enum.with_index(1)
      |> Enum.map(fn {row, index} ->
        %Message{
          data: row,
          acknowledger: {Broadway.NoopAcknowledger, nil, nil},
          metadata: %{
            index: index,
            registry: registry,
            pipeline_name: pipeline_name,
            context: context,
            caller: caller
          }
        }
      end)

    {:producer, events}
  end

  @impl true
  def handle_demand(incoming_demand, events) when incoming_demand > 0 do
    {to_send, remaining} = Enum.split(events, incoming_demand)
    {:noreply, to_send, remaining}
  end
end
