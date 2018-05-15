defmodule MrNoisyTest do
  use ExUnit.Case
  doctest MrNoisy

  test "greets the world" do
    assert MrNoisy.hello() == :world
  end
end
