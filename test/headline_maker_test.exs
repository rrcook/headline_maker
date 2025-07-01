defmodule HeadlineMakerTest do
  use ExUnit.Case
  doctest HeadlineMaker

  test "greets the world" do
    assert HeadlineMaker.hello() == :world
  end
end
