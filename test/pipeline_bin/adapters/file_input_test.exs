defmodule PipelineBin.Adapters.FileInputTest do
  use ExUnit.Case, async: false

  alias PipelineBin.Adapters.FileInput
  alias PipelineBin.Pipelines

  test "runs user_ingest over json rows" do
    path = temp_path("users.json")

    json_payload = """
    [
      {"external_id":"user-1","name":"  Ada  Lovelace ","email":" ADA@EXAMPLE.COM "},
      {"external_id":"user-2","name":"Grace Hopper","email":"grace@example.com"}
    ]
    """

    File.write!(path, json_payload)

    assert {:ok, results} =
             FileInput.run_file(Pipelines.registry(), :user_ingest, path, %{persist_logs?: false})

    assert Enum.all?(results, &(&1.status == :ok))
    assert Enum.at(results, 0).output.name == "Ada Lovelace"
    assert Enum.at(results, 0).output.email == "ada@example.com"
  end

  test "runs order_ingest over csv rows and reports row errors" do
    path = temp_path("orders.csv")

    csv_payload = """
    order_id,user_id,amount_cents,currency
    ord-1,usr-1,2500,usd
    ord-2,usr-2,0,eur
    """

    File.write!(path, csv_payload)

    assert {:ok, results} =
             FileInput.run_file(Pipelines.registry(), :order_ingest, path, %{persist_logs?: false})

    assert Enum.at(results, 0).status == :ok
    assert Enum.at(results, 0).output.currency == "USD"

    assert Enum.at(results, 1).status == :error
    assert Enum.at(results, 1).reason == {:validate_amount, {:invalid_positive_integer, :amount_cents}}
  end

  defp temp_path(filename) do
    dir = Path.join(System.tmp_dir!(), "pipeline_bin_tests")
    File.mkdir_p!(dir)
    Path.join(dir, "#{System.unique_integer([:positive])}_#{filename}")
  end
end
