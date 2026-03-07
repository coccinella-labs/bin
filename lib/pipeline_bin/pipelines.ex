defmodule PipelineBin.Pipelines do
  @moduledoc """
  Pipeline registry for reusable domain pipelines.
  """

  alias PipelineBin.Pipelines.OrderIngest
  alias PipelineBin.Pipelines.UserIngest

  @spec registry() :: map()
  def registry do
    %{
      order_ingest: OrderIngest.build(),
      user_ingest: UserIngest.build()
    }
  end

  @spec resolve_name(map(), atom() | String.t()) :: {:ok, atom()} | {:error, {:unknown_pipeline, any()}}
  def resolve_name(registry, name) when is_map(registry) and is_atom(name) do
    if Map.has_key?(registry, name), do: {:ok, name}, else: {:error, {:unknown_pipeline, name}}
  end

  def resolve_name(registry, name) when is_map(registry) and is_binary(name) do
    case Enum.find(Map.keys(registry), &(Atom.to_string(&1) == name)) do
      nil -> {:error, {:unknown_pipeline, name}}
      atom_name -> {:ok, atom_name}
    end
  end
end
