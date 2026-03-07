defmodule PipelineBinTest do
  use ExUnit.Case, async: true

  test "builds and runs a happy-path pipeline" do
    pipeline =
      PipelineBin.new_pipeline(:normalize_user)
      |> PipelineBin.add_step(:trim_name, fn data, _ctx ->
        {:ok, Map.update!(data, :name, &String.trim/1)}
      end)
      |> PipelineBin.add_step(:downcase_email, fn data, _ctx ->
        {:ok, Map.update!(data, :email, &String.downcase/1)}
      end)

    input = %{name: "  Ada Lovelace  ", email: "ADA@EXAMPLE.COM"}

    assert {:ok, %{name: "Ada Lovelace", email: "ada@example.com"}} =
             PipelineBin.run(pipeline, input)
  end
end
