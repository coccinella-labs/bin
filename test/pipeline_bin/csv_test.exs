defmodule PipelineBin.CSVTest do
  use ExUnit.Case, async: true

  alias PipelineBin.CSV

  test "parses quoted CSV fields with commas" do
    path = temp_path("quoted.csv")

    File.write!(
      path,
      """
      external_id,name,email
      user-1,"Ada, Lovelace",ada@example.com
      """
    )

    assert {:ok, [row]} = CSV.parse_file(path)
    assert row.external_id == "user-1"
    assert row.name == "Ada, Lovelace"
    assert row.email == "ada@example.com"
  end

  defp temp_path(filename) do
    dir = Path.join(System.tmp_dir!(), "pipeline_bin_csv_tests")
    File.mkdir_p!(dir)
    Path.join(dir, "#{System.unique_integer([:positive])}_#{filename}")
  end
end
