defmodule Commandline.CLI.Test do
  use ExUnit.Case

  alias Commandline.CLI

  test "Explicit help test" do
    assert CLI.main(["--help"]) == :ok
  end

  test "Error help test" do
    assert CLI.main(["--foo"]) == :ok
  end
end
