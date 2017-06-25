defmodule Metex.Worker do
  use GenServer
  require Logger

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def init(state) do
    {:ok, state}
  end

  def get_state(pid) do
    GenServer.call(pid, :get_state)
  end

  def reset_state(pid) do
    GenServer.cast(pid, :reset_state)
  end

  def get_temperature(pid, location) do
    GenServer.call(pid, {:location, location})
  end

  ## Server API
  ## GenServer Callbacks

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:location, location}, _form, state) do
    case temperature_of(location) do
      {:ok, temp} ->
        new_state = update_state(state, location)
        {:reply, "#{temp}°C", new_state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_cast(:reset_state, _state) do
    new_state = %{}
    {:noreply, new_state}
  end


  ## Helper Functions

  # def loop do
  #   receive do
  #     {sender_pid, location} ->
  #       send(sender_pid, {:ok, temperature_of(location)})
  #     _ ->
  #       Logger.info "don't know how to process this message"
  #
  #   after
  #     1_000 -> loop()
  #   end
  # end

  defp temperature_of(location) do
    url_for(location) |> HTTPoison.get |> parse_repsonse
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

  defp update_state(old_state, location) do
    initial = 1
    Map.update(old_state, location, initial, &(&1 + 1))
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
