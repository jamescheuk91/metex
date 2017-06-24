defmodule Metex.Coordinator do

  def loop(results \\ [], results_expected) do
    receive do
      {:ok, result} ->
        new_results = [result | results]
        results_count = Enum.count(new_results)
        if results_expected == results_count do
          send self(), :exit
        end
        loop(new_results, results_expected)
      :exit ->
        formatted_results = results |> Enum.sort |> Enum.join(", ")
        IO.puts(formatted_results)
      _ ->
        loop(results, results_expected)
    after
      1_000 -> loop(results, results_expected)
    end
  end

end
