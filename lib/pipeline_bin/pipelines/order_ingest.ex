defmodule PipelineBin.Pipelines.OrderIngest do
  @moduledoc """
  Validates and normalizes inbound order payloads.
  """

  alias PipelineBin.Pipeline
  alias PipelineBin.Pipelines.StepHelpers

  @spec build() :: Pipeline.t()
  def build do
    Pipeline.new(:order_ingest)
    |> Pipeline.add_step(
      :validate_required_fields,
      StepHelpers.require_fields([:order_id, :user_id, :amount_cents, :currency])
    )
    |> Pipeline.add_step(:normalize_currency, StepHelpers.normalize_uppercase(:currency))
    |> Pipeline.add_step(:validate_amount, StepHelpers.validate_positive_integer(:amount_cents))
    |> Pipeline.add_step(:stamp_ingested_at, StepHelpers.stamp_datetime(:ingested_at, :ingested_at))
  end
end
