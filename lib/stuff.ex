defmodule Stuff do
  def paths(directory, prefix, number) do
    start1 = System.monotonic_time(:microsecond)
    standard_paths(directory, prefix, number)
    duration1 = System.monotonic_time(:microsecond) - start1
    start2 = System.monotonic_time(:microsecond)
    flow_paths(directory, prefix, number)
    duration2 = System.monotonic_time(:microsecond) - start2
    IO.puts ("Standard time to create #{inspect number} path strings: #{inspect duration1} usecS")
    IO.puts ("Flow(defaults) time to create #{inspect number} path strings: #{inspect duration2} usecS")
  end
  def standard_paths(directory, prefix, number) do
    for count <- 1..number do
      do_path_compute(directory, prefix, count)
    end
    :ok
  end
  def flow_paths(directory, prefix, number) do
    flow = Flow.from_enumerable(1..number) |> Flow.map(&do_path_compute(directory, prefix, &1))
    Flow.run(flow)
    # for count <- 1..number do
    #   file_name = prefix <> Integer.to_string(count) <> ".txt"
    #   path = Path.join(directory, file_name)
    #   Map.put(result_map, file_name, path)
    # end
  end

  def do_path_compute(directory, prefix, value) do
    file_name = prefix <> Integer.to_string(value) <> ".txt"
    path = Path.join(directory, file_name)
    # IO.puts "Path for #{inspect value}: #{path}"
  end

  def create_files_fixed(directory, prefix, number) do
    File.mkdir!(directory)

    for count <- 1..number do
      file_name = prefix <> Integer.to_string(count) <> ".txt"
      path = Path.join(directory, file_name)
      {:ok, device} = File.open(path, [:write, :utf8])
      write_contents(path, device, 1)
    end
  end

  def create_files_rand_size(directory, prefix, number, max_k) do
    File.mkdir!(directory)

    for count <- 1..number do
      file_name = prefix <> Integer.to_string(count) <> ".txt"
      path = Path.join(directory, file_name)
      {:ok, device} = File.open(path, [:write, :utf8])
      write_contents(path, device, :rand.uniform(max_k))
    end
  end

  def write_contents(path, device, coda_count) do
    IO.write(device, "Test File #{path}")
    for _count <- 1..coda_count do
      write_coda(device)
    end
  end

  def write_coda(device) do
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
    IO.write(device, "\r\n123456789012345678901234567890123456789012345678901234567890")
    IO.write(device, "\r\nAAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF")
  end
end