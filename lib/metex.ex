defmodule Metex do
  @moduledoc """
  Documentation for Metex.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Metex.hello
      :world

  """
  def hello do
    :world
  end

  def temperature_of(%MapSet{} = cities) do
    cities_count = MapSet.size(cities)
    coodinator_pid = spawn(Metex.Coordinator, :loop, [[], cities_count])
    cities |> Enum.each(fn(city) ->
      worker_pid = spawn(Metex.Worker, :loop, [])
      send worker_pid, {coodinator_pid, city}
    end)
  end
end
