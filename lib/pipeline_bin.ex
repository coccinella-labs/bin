defmodule PipelineBin do
  @moduledoc """
  Public API for building and running data pipelines.
  """

  alias PipelineBin.Pipeline

  @doc """
  Creates a new pipeline.
  """
  def new_pipeline(name), do: Pipeline.new(name)

  @doc """
  Adds a step to a pipeline.
  """
  def add_step(%Pipeline{} = pipeline, name, fun), do: Pipeline.add_step(pipeline, name, fun)

  @doc """
  Runs a pipeline with initial input and optional context.
  """
  def run(%Pipeline{} = pipeline, input, context \\ %{}), do: Pipeline.run(pipeline, input, context)
end
