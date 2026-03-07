defmodule PipelineBin.Pipelines.UserIngestTest do
  use ExUnit.Case, async: true

  alias PipelineBin.Pipelines
  alias PipelineBin.Runner

  test "normalizes inbound user data" do
    registry = Pipelines.registry()
    ingested_at = ~U[2026-03-08 01:00:00Z]

    input = %{
      external_id: "user-123",
      name: "  Ada    Lovelace ",
      email: " ADA@EXAMPLE.COM "
    }

    assert {:ok,
            %{
              external_id: "user-123",
              name: "Ada Lovelace",
              email: "ada@example.com",
              ingested_at: ~U[2026-03-08 01:00:00Z]
            }} =
             Runner.run(registry, :user_ingest, input, %{ingested_at: ingested_at, persist_logs?: false})
  end

  test "fails when required fields are missing" do
    registry = Pipelines.registry()
    input = %{external_id: "user-123", name: "Ada Lovelace"}

    assert {:error, {:validate_required_fields, {:missing_fields, [:email]}}} =
             Runner.run(registry, :user_ingest, input, %{persist_logs?: false})
  end

  test "fails when email format is invalid" do
    registry = Pipelines.registry()
    input = %{external_id: "user-123", name: "Ada Lovelace", email: "not-an-email"}

    assert {:error, {:normalize_email, :invalid_email}} =
             Runner.run(registry, :user_ingest, input, %{persist_logs?: false})
  end
end
