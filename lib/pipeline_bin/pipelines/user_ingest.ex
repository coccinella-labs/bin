defmodule PipelineBin.Pipelines.UserIngest do
  @moduledoc """
  Validates and normalizes inbound user payloads.
  """

  alias PipelineBin.Pipeline
  alias PipelineBin.Pipelines.StepHelpers

  @spec build() :: Pipeline.t()
  def build do
    Pipeline.new(:user_ingest)
    |> Pipeline.add_step(:validate_required_fields, StepHelpers.require_fields([:external_id, :name, :email]))
    |> Pipeline.add_step(:normalize_name, StepHelpers.trim_and_squish(:name))
    |> Pipeline.add_step(:normalize_email, StepHelpers.normalize_email(:email))
    |> Pipeline.add_step(:stamp_ingested_at, StepHelpers.stamp_datetime(:ingested_at, :ingested_at))
  end
end
