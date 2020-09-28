defmodule StatsCollector do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    unix_now = DateTime.to_unix(DateTime.utc_now())
    # state tuple: {unix_start_time, unix_last_write_time, stats_map}
    {:ok, {unix_now, unix_now, Map.new()}}
  end

  # ----- API

  def add_channel_tuple_list(channel_tuple_list) do
    GenServer.call(__MODULE__, {:add, channel_tuple_list})
  end

  def get_state() do
    GenServer.call(__MODULE__, :get)
  end

  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  # ----- Message Handlers

  def handle_call({:add, channel_tuple_list}, _from, mapset) do
    new_mapset =
      mapset
      |> add_property_datatype_tuples(channel_tuple_list)

    {:reply, :ok, new_mapset}
  end

  def handle_call(:get, _from, mapset) do
    {:reply, {:ok, Enum.to_list(mapset)}, mapset}
  end

  def handle_call(:stop, _from, mapset) do
    {:stop, :normal, mapset}
  end

  # ----- Helper Functions

  def add_property_datatype_tuples(mapset, []), do: mapset

  def add_property_datatype_tuples(mapset, [property_datatype_tuple | more]) do
    add_property_datatype_tuples(MapSet.put(mapset, property_datatype_tuple), more)
  end
end
