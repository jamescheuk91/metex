defmodule Metex.Worker do
  require Logger

  def loop do
    receive do
      {sender_pid, location} ->
        send(sender_pid, {:ok, temperature_of(location)})
      _ ->
        Logger.info "don't know how to process this message"

    after
      1_000 -> loop()
    end
  end

  def temperature_of(location) do
    result = url_for(location) |> HTTPoison.get |> parse_repsonse

    case result do
      {:ok, temp} ->
        "#{location}: #{temp}°C"
      :error ->
        "#{location} not found"
    end
  end


  defp url_for(location) do
    location = URI.encode(location)
    "http://api.openweathermap.org/data/2.5/weather?q=#{location}&appid=#{apiKey()}"
  end

  defp parse_repsonse({
    :ok,
    %HTTPoison.Response{body: body, status_code: 200}
  }) do
    body |> JSON.decode! |> compute_temperature
  end

  defp parse_repsonse(_) do
    :error
  end

  defp compute_temperature(json) do
    try do
      temp = (json["main"]["temp"] - 273.15) |> Float.round(1)
      {:ok, temp}
    rescue
      _ -> :error
    end
  end

  defp apiKey do
    Application.get_env(:metex, __MODULE__)[:api_key]
  end

end
