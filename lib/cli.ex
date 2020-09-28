defmodule Commandline.CLI do
  alias TDMS.Operate
  require Logger

  def main(args) do
    options = [
      switches: [
        mode: :string,
        repeat: :integer,
        help: :boolean,
        preview: :boolean,
        verbose: :boolean,
        file_mode: :boolean
      ],
      aliases: [m: :mode, h: :help, p: :preview, v: :verbose, f: :file_mode]
    ]

    {opts, args, invalid_from_parse} = OptionParser.parse(args, options)
    IO.inspect(opts, label: "Command Line Options (opts)")
    IO.inspect(args, label: "Command Line Arguments (args)")
    IO.inspect(invalid_from_parse, label: "Command Line Invalid Arguments (invalid_from_parse)")
    mode_flag = get_string_flag(:mode, opts)
    repeat_count = get_integer_flag(:repeat, opts)
    do_help = check_boolean_flag(:help, opts)
    do_preview = check_boolean_flag(:preview, opts)
    do_verbose = check_boolean_flag(:verbose, opts)
    do_file_mode = check_boolean_flag(:file_mode, opts)
    valid_args = valid_args?(mode_flag, Enum.count(args), invalid_from_parse)
    # IO.puts("mode_flag=#{inspect(mode_flag)}")
    # IO.puts("do_help=#{inspect(do_help)}")
    # IO.puts("do_preview=#{inspect(do_preview)}")
    # IO.puts("do_verbose=#{inspect(do_verbose)}")
    # IO.puts("valid_args=#{inspect(valid_args)}")
    do_command(
      valid_args,
      mode_flag,
      args,
      {do_help, do_preview, do_verbose, repeat_count, do_file_mode}
    )
  end

  defp valid_args?(_, _, invalid_from_parse) when length(invalid_from_parse) > 0, do: false
  defp valid_args?("copyBucket", 3, _), do: true
  defp valid_args?("copyBucket", 4, _), do: true
  defp valid_args?("getObjectInfo", 2, _), do: true
  defp valid_args?("tdmsLocal", 1, _), do: true
  defp valid_args?("tdmsLocal", 2, _), do: true
  defp valid_args?("uploadDirectory", 3, _), do: true
  defp valid_args?("getStats", 2, _), do: true
  defp valid_args?("getStats", 3, _), do: true
  defp valid_args?(_, _, _), do: false

  defp get_string_flag(flag, opts) do
    result = Enum.find(opts, false, fn {k, _v} -> k == flag end)
    value = get_flag_value(result)
    get_string_flag_inner(value)
  end

  defp get_flag_value({_, value}), do: value
  defp get_flag_value(_), do: nil

  defp get_string_flag_inner(nil), do: nil
  defp get_string_flag_inner("getStats"), do: "getStats"
  defp get_string_flag_inner("copyBucket"), do: "copyBucket"
  defp get_string_flag_inner("getObjectInfo"), do: "getObjectInfo"
  defp get_string_flag_inner("tdmsLocal"), do: "tdmsLocal"
  defp get_string_flag_inner("uploadDirectory"), do: "uploadDirectory"
  defp get_string_flag_inner(_), do: nil

  defp get_integer_flag(flag, opts) do
    result = Enum.find(opts, false, fn {k, _v} -> k == flag end)
    get_flag_value(result)
  end

  defp check_boolean_flag(flag, opts) do
    result = Enum.find(opts, false, fn {k, v} -> k == flag and v == true end)
    check_boolean_flag_inner(result)
  end

  defp check_boolean_flag_inner(false), do: false
  defp check_boolean_flag_inner({_key, value}), do: value

  defp do_command(false, _mode_flag, _args, _flags),
    do: output_help_text()

  defp do_command(
         _valid_args,
         _mode_flag,
         _args,
         {true, _do_preview, _do_verbose, _repeat_count, _do_flag_mode}
       ),
       do: output_help_text()

  defp do_command(true, "getStats", args, {_, _, _, _, do_file_mode}) do
    {bq_table_root, output_file_suffix, working_directory} = get_get_stats_args(args)
    do_get_stats(bq_table_root, output_file_suffix, working_directory, do_file_mode)
  end

  defp do_command(_, "copyBucket", args, {_, true, _do_verbose, _, _}) do
    {source_bucket, source_object_specifier, _destination_bucket, _destination_root} =
      get_copy_bucket_args(args)

    output_preview_text(source_bucket, source_object_specifier, false)
  end

  defp do_command(true, "copyBucket", args, _) do
    {source_bucket, source_object_specifier, destination_bucket, destination_root} =
      get_copy_bucket_args(args)

    result = get_objects_list(source_bucket, source_object_specifier)
    do_copy_bucket_to_bucket(result, destination_bucket, destination_root)
  end

  defp do_command(true, "getObjectInfo", args, {_, _, do_verbose, _, _}) do
    [source_bucket, source_object_specifier] = args
    result = get_objects_list(source_bucket, source_object_specifier)
    output_objects(result, do_verbose)
  end

  defp do_command(true, "tdmsLocal", args, _) do
    [tdms_file, output_directory] = args
    process_tdms_file(tdms_file, output_directory)
  end

  defp do_command(true, "uploadDirectory", args, {_, _, _, repeat_count, _}) do
    upload_directory(args, repeat_count)
  end

  defp do_command(true, "uploadDirectory", args, _) do
    upload_directory(args, 1)
  end

  defp do_command(true, _, _, _), do: output_help_text()

  defp do_get_stats(bq_table_root, output_file_suffix, working_directory, do_file_mode) do
    Logger.info(
      "getStats do_file_mode=#{inspect(do_file_mode)} #{bq_table_root} #{output_file_suffix} #{
        working_directory
      }"
    )

    ingest_phase_1_stats_csv_file_name = "ingest-phase-1-stats." <> output_file_suffix <> ".csv"

    ingest_phase_1_stats_csv_path =
      Path.join(working_directory, ingest_phase_1_stats_csv_file_name)

    ingest_batch_metadata_batch_stats_csv_file_name =
      "ingest-batch-metadata-batch-stats." <> output_file_suffix <> ".csv"

    ingest_batch_metadata_batch_stats_csv_path =
      Path.join(working_directory, ingest_batch_metadata_batch_stats_csv_file_name)

    ingest_batch_metadata_file_stats_csv_file_name =
      "ingest-batch-metadata-file-stats." <> output_file_suffix <> ".csv"

    ingest_batch_metadata_file_stats_csv_path =
      Path.join(working_directory, ingest_batch_metadata_file_stats_csv_file_name)

    ingest_channels_to_bq_batch_stats_csv_file_name =
      "ingest-channels-to-bq-batch-stats." <> output_file_suffix <> ".csv"

    ingest_channels_to_bq_batch_stats_csv_path =
      Path.join(working_directory, ingest_channels_to_bq_batch_stats_csv_file_name)

    ingest_channels_to_bq_file_stats_csv_file_name =
      "ingest-channels-to-bq-file-stats." <> output_file_suffix <> ".csv"

    ingest_channels_to_bq_file_stats_csv_path =
      Path.join(working_directory, ingest_channels_to_bq_file_stats_csv_file_name)

    ingest_metadata_to_bq_chunk_stats_csv_file_name =
      "ingest-metadata-to-bq" <> output_file_suffix <> ".csv"

    ingest_metadata_to_bq_chunk_stats_csv_path =
      Path.join(working_directory, ingest_metadata_to_bq_chunk_stats_csv_file_name)

    stats_map =
      %{}
      |> Map.put(
        :ingest_phase_1,
        {ingest_phase_1_stats_csv_file_name, ingest_phase_1_stats_csv_path, %{}}
      )
      |> Map.put(
        :ingest_batch_metadata_batch,
        {ingest_batch_metadata_batch_stats_csv_file_name,
         ingest_batch_metadata_batch_stats_csv_path, %{}}
      )
      |> Map.put(
        :ingest_batch_metadata_file,
        {ingest_batch_metadata_file_stats_csv_file_name,
         ingest_batch_metadata_file_stats_csv_path, %{}}
      )
      |> Map.put(
        :ingest_channels_to_bq_batch,
        {ingest_channels_to_bq_batch_stats_csv_file_name,
         ingest_channels_to_bq_batch_stats_csv_path, %{}}
      )
      |> Map.put(
        :ingest_channels_to_bq_file,
        {ingest_channels_to_bq_file_stats_csv_file_name,
         ingest_channels_to_bq_file_stats_csv_path, %{}}
      )
      |> Map.put(
        :ingest_metadata_to_bq_chunk,
        {ingest_metadata_to_bq_chunk_stats_csv_file_name,
         ingest_metadata_to_bq_chunk_stats_csv_path, %{}}
      )

    do_get_stats(bq_table_root, output_file_suffix, working_directory, stats_map, do_file_mode)
  end

  defp file_process_ingest_phase_1(stats_map) do
    ingest_phase_1_tuple = stats_map.ingest_phase_1
    path = elem(ingest_phase_1_tuple, 1)
    ingest_phase_1_stats = read_ingest_phase_1_csv(path)

    %{
      stats_map
      | ingest_phase_1:
          {elem(ingest_phase_1_tuple, 0), elem(ingest_phase_1_tuple, 1), ingest_phase_1_stats}
    }
  end

  defp read_ingest_phase_1_csv(path) do
    stream =
      File.stream!(path)
      |> Stream.map(&String.trim(&1))
      |> Stream.map(&String.split(&1, ","))

    IO.puts("\r\n AAAA.1 stream=#{inspect(stream)}")

    result = Enum.to_list(stream)
    IO.puts("\r\n AAAA.2 result=#{inspect(result)}")
  end

  defp do_get_stats(bq_table_root, output_file_suffix, working_directory, stats_map, true) do
    Logger.info("getStats(file mode) #{bq_table_root} #{output_file_suffix} #{working_directory}")
    Logger.info("getStats(file mode) stats_map=#{inspect(stats_map)}")
    stats_map = file_process_ingest_phase_1(stats_map)
    Logger.info("getStats(file mode) stats_map=#{inspect(stats_map)}")
  end

  defp do_get_stats(bq_table_root, output_file_suffix, working_directory, stats_map, false) do
    Logger.info(
      "getStats(Kafka mode) #{bq_table_root} #{output_file_suffix} #{working_directory}"
    )

    Logger.info("getStats(Kafka mode) stats_map=#{inspect(stats_map)}")

    # import Supervisor.Spec

    # Logger.info("Kafka Consumers: STARTING")
    # Logger.info("Kafka Topics To Consume: #{inspect(@stats_topics)}")

    # consumer_group_opts = [
    #   # setting for the ConsumerGroup
    #   #
    #   heartbeat_interval: 1_000,
    #   # this setting will be forwarded to the GenConsumer
    #   commit_interval: 1_000
    # ]

    # children = [
    #   supervisor(
    #     KafkaEx.ConsumerGroup,
    #     [
    #       Sdlti.BatchMetadataBatchStats.GenConsumer,
    #       "ingest-batch-metadata-consumer-group",
    #       ["ingest-batch-metadata-batch-stats"],
    #       consumer_group_opts
    #     ],
    #     id: "topic-ingest-batch-metadata-batch"
    #   )
    # ]

    # Supervisor.start_link(children, strategy: :one_for_one)
    # Logger.info("Kafka Consumers: STARTED")
  end

  defp upload_directory(args, repeat_count) do
    [source_directory, destination_bucket, destination_root] = args

    IO.puts("Building file list for directory #{source_directory}")
    start = System.monotonic_time()
    absolute_source_root = Path.expand(source_directory)
    source_files = list_all_files(absolute_source_root)
    duration = (System.monotonic_time() - start) / 1_000_000

    IO.puts(
      "Found #{Enum.count(source_files)} files in the directory tree, elapsed time: #{duration} sec\r\n"
    )

    IO.puts("Preparing to upload ...")

    params =
      List.flatten(
        for number <- 1..repeat_count do
          Enum.map(source_files, fn x ->
            {destination_bucket, x,
             Path.join(
               destination_root,
               "/#{number}_" <> String.trim_leading(x, absolute_source_root <> "/")
             )}
          end)
        end
      )

    # IO.puts("..repeat_count = #{inspect(repeat_count)}")
    # IO.puts("..params = #{inspect(params)}")

    IO.puts("Beginning upload ...")

    start = System.monotonic_time()
    # upload_files(params)
    flow =
      params
      |> Flow.from_enumerable(min_demand: 8, max_demand: 16)
      |> Flow.map(&upload_file/1)

    Flow.run(flow)

    duration = (System.monotonic_time() - start) / 1_000_000
    IO.puts("\r\nUpload count: #{Enum.count(params)} duration: #{duration} sec\r\n")
  end

  def list_all_files(filepath) do
    list_all_files_inner(filepath)
  end

  defp list_all_files_inner(filepath) do
    expand_files(File.ls(filepath), filepath)
  end

  defp expand_files({:ok, files}, path) do
    IO.puts("... + #{path}")

    files
    |> Enum.flat_map(&list_all_files_inner("#{path}/#{&1}"))
  end

  defp expand_files({:error, _}, path) do
    [path]
  end

  def upload_files([]), do: :ok

  def upload_files([params | remaining_params]) do
    upload_file(elem(params, 1), elem(params, 0), elem(params, 2))
    upload_files(remaining_params)
  end

  def upload_file({destination_bucket, local_file_path, destination_object_name}) do
    IO.puts("... #{destination_object_name} ")
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    IO.puts("... calling GCS")

    result =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
        conn,
        destination_bucket,
        "multipart",
        %{name: destination_object_name},
        local_file_path
      )

    # IO.puts("... result=#{inspect(result)}")
    result
  end

  def upload_file(local_file_path, destination_bucket, destination_object_name) do
    # IO.puts(
    #   ">>> bucket=#{destination_bucket}, source=#{local_file_path}, destination=#{
    #     destination_object_name
    #   }"
    # )

    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    conn = GoogleApi.Storage.V1.Connection.new(token.token)

    GoogleApi.Storage.V1.Api.Objects.storage_objects_insert_simple(
      conn,
      destination_bucket,
      "multipart",
      %{name: destination_object_name},
      local_file_path
    )
  end

  defp process_tdms_file(tdms_file, nil),
    do: process_tdms_file(tdms_file, Path.dirname(tdms_file))

  defp process_tdms_file(tdms_file, output_directory) do
    Operate.process_tdms_file(tdms_file, output_directory)
  end

  defp get_get_stats_args([
         bq_table_root,
         output_file_suffix,
         working_directory
       ]),
       do: {bq_table_root, output_file_suffix, working_directory}

  defp get_get_stats_args([
         bq_table_root,
         output_file_suffix
       ]),
       do: {bq_table_root, output_file_suffix, "./"}

  defp get_copy_bucket_args([source_bucket, source_object_specifier, destination_bucket]),
    do: {source_bucket, source_object_specifier, destination_bucket, nil}

  defp get_copy_bucket_args([
         source_bucket,
         source_object_specifier,
         destination_bucket,
         destination_root
       ]),
       do: {source_bucket, source_object_specifier, destination_bucket, destination_root}

  defp do_copy_bucket_to_bucket([], destination_bucket, _destination_root),
    do: IO.puts("\r\nCopy to bucket #{destination_bucket} complete.\r\n")

  defp do_copy_bucket_to_bucket([source_object | remaining], destination_bucket, nil) do
    copy_bucket_to_bucket(
      source_object.bucket,
      source_object.name,
      destination_bucket,
      source_object.name
    )

    do_copy_bucket_to_bucket(remaining, destination_bucket, nil)
  end

  defp do_copy_bucket_to_bucket([source_object | remaining], destination_bucket, destination_root) do
    copy_bucket_to_bucket(
      source_object.bucket,
      source_object.name,
      destination_bucket,
      destination_root <> "/" <> source_object.name
    )

    do_copy_bucket_to_bucket(remaining, destination_bucket, destination_root)
  end

  defp copy_bucket_to_bucket(source_bucket, source_object, destination_bucket, destination_object) do
    IO.puts(
      "Copying from #{source_bucket}/#{source_object} to #{destination_bucket}/#{
        destination_object
      }"
    )

    conn = get_connection()

    GoogleApi.Storage.V1.Api.Objects.storage_objects_copy(
      conn,
      source_bucket,
      source_object,
      destination_bucket,
      destination_object
    )
  end

  defp output_preview_text(source_bucket, source_object_specifier, do_verbose) do
    matches = get_objects_list(source_bucket, source_object_specifier)
    output_objects(matches, do_verbose)
  end

  defp output_objects([], _do_verbose) do
  end

  defp output_objects([head | remaining], do_verbose) do
    output_object_text(head, do_verbose)
    output_objects(remaining, do_verbose)
  end

  defp output_object_text(google_object, false) do
    IO.puts(
      "\r\n bucket=#{inspect(google_object.bucket)}\r\n   name=#{inspect(google_object.name)}\r\n   metadata=#{
        inspect(google_object.metadata)
      }\r\n   contentType=#{inspect(google_object.contentType)}\r\n   kind=#{
        inspect(google_object.kind)
      }\r\n   timeCreated=#{inspect(google_object.timeCreated)}\r\n   updated=#{
        inspect(google_object.updated)
      }"
    )
  end

  # %GoogleApi.Storage.V1.Model.Object{acl: nil, bucket: "ni-mwatson-lti-1", cacheControl: nil, componentCount: nil, contentDisposition: nil, contentEncoding: nil, contentLanguage: nil, contentType: "text/plain", crc32c: "z+75uA==", customerEncryption: nil, etag: "CNDq0cyFuegCEAE=", eventBasedHold: nil, generation: "1585256751986000", id: "ni-mwatson-lti-1/d1/d1.1/d1.1.2/t1.txt/1585256751986000", kind: "storage#object", kmsKeyName: nil, md5Hash: "h74nXiChqtM3FhenvPAx/g==", mediaLink: "https://storage.googleapis.com/download/storage/v1/b/ni-mwatson-lti-1/o/d1%2Fd1.1%2Fd1.1.2%2Ft1.txt?generation=1585256751986000&alt=media", metadata: nil, metageneration: "1", name: "d1/d1.1/d1.1.2/t1.txt", owner: nil, retentionExpirationTime: nil, selfLink: "https://www.googleapis.com/storage/v1/b/ni-mwatson-lti-1/o/d1%2Fd1.1%2Fd1.1.2%2Ft1.txt", size: "124", storageClass: "STANDARD", temporaryHold: nil, timeCreated: ~U[2020-03-26 21:05:51.985Z], timeDeleted: nil, timeStorageClassUpdated: ~U[2020-03-26 21:05:51.985Z], updated: ~U[2020-03-26 21:05:51.985Z]}

  defp output_object_text(google_object, true) do
    IO.puts("\r\n bucket=#{inspect(google_object.bucket)}")
    IO.puts("   name=#{inspect(google_object.name)}")
    IO.puts("   acl=#{inspect(google_object.acl)}")
    IO.puts("   cacheControl=#{inspect(google_object.cacheControl)}")
    IO.puts("   componentCount=#{inspect(google_object.componentCount)}")
    IO.puts("   contentDisposition=#{inspect(google_object.contentDisposition)}")
    IO.puts("   contentEncoding=#{inspect(google_object.contentEncoding)}")
    IO.puts("   contentLanguage=#{inspect(google_object.contentLanguage)}")
    IO.puts("   contentType=#{inspect(google_object.contentType)}")
    IO.puts("   crc32c=#{inspect(google_object.crc32c)}")
    IO.puts("   customerEncryption=#{inspect(google_object.customerEncryption)}")
    IO.puts("   etag=#{inspect(google_object.etag)}")
    IO.puts("   eventBasedHold=#{inspect(google_object.eventBasedHold)}")
    IO.puts("   generation=#{inspect(google_object.generation)}")
    IO.puts("   id=#{inspect(google_object.id)}")
    IO.puts("   kind=#{inspect(google_object.kind)}")
    IO.puts("   kmsKeyName=#{inspect(google_object.kmsKeyName)}")
    IO.puts("   md5Hash=#{inspect(google_object.md5Hash)}")
    IO.puts("   mediaLink=#{inspect(google_object.mediaLink)}")
    IO.puts("   metadata=#{inspect(google_object.metadata)}")
    IO.puts("   metageneration=#{inspect(google_object.metageneration)}")
    IO.puts("   retentionExpirationTime=#{inspect(google_object.retentionExpirationTime)}")
    IO.puts("   selfLink=#{inspect(google_object.selfLink)}")
    IO.puts("   storageClass=#{inspect(google_object.storageClass)}")
    IO.puts("   temporaryHold=#{inspect(google_object.temporaryHold)}")
    IO.puts("   timeCreated=#{inspect(google_object.timeCreated)}")
    IO.puts("   timeDeleted=#{inspect(google_object.timeDeleted)}")
    IO.puts("   timeStorageClassUpdated=#{inspect(google_object.timeStorageClassUpdated)}")
    IO.puts("   updated=#{inspect(google_object.updated)}")
  end

  defp get_objects_list(source_bucket, source_object_specifier) do
    source_object_segments = String.split(source_object_specifier, "/", trim: true)

    first_wildcard_index =
      Enum.find_index(source_object_segments, fn x -> String.contains?(x, "*") end)

    {prefix, _remainder_segments} =
      get_prefix(first_wildcard_index, source_object_segments, source_object_specifier)

    conn = get_connection()

    {:ok, objects_list} =
      GoogleApi.Storage.V1.Api.Objects.storage_objects_list(
        conn,
        source_bucket,
        [{:prefix, prefix}]
      )

    find_matches(objects_list.items, source_object_segments)
  end

  defp get_prefix(nil, segments, source_object_specifier) do
    last_segment = Enum.at(segments, Enum.count(segments) - 1)
    trimmed_specifier = String.trim_trailing(source_object_specifier, last_segment)
    prefix = String.replace(trimmed_specifier, "//", "/")
    {prefix, last_segment}
  end

  defp get_prefix(first_wildcard_index, segments, _source_object_specifier) do
    prefix = String.replace(build_string_until(segments, "/", first_wildcard_index), "//", "/")

    remainder_segments =
      get_remainder_segments(segments, first_wildcard_index, Enum.count(segments) - 1, [])

    {prefix, remainder_segments}
  end

  defp get_remainder_segments(segments, current_index, max_index, remainder_segments)
       when current_index <= max_index do
    get_remainder_segments(
      segments,
      current_index + 1,
      max_index,
      remainder_segments ++ [Enum.at(segments, current_index)]
    )
  end

  defp get_remainder_segments(_segments, _current_index, _max_index, remainder_segments),
    do: remainder_segments

  defp build_string_until(segments, delimiter, index) do
    build_string_until(segments, delimiter, index, "")
  end

  defp build_string_until(_segments, _delimiter, 0, built_string), do: built_string

  defp build_string_until([segment | remaining_segments], delimiter, index, built_string) do
    build_string_until(
      remaining_segments,
      delimiter,
      index - 1,
      built_string <> segment <> delimiter
    )
  end

  defp find_matches(objects_list, source_object_segments) do
    list_no_paths = Enum.filter(objects_list, fn x -> String.last(x.name) != "/" end)
    regex_string = build_regex_string(source_object_segments, "")
    {:ok, regex} = Regex.compile(regex_string)
    Enum.filter(list_no_paths, fn x -> Regex.match?(regex, x.name) end)
  end

  defp build_regex_string([], regex_string), do: String.trim_trailing(regex_string, "\\/")

  defp build_regex_string([segment | remaining_segments], regex_string) do
    new_regex_string =
      build_regex_segment_string(String.contains?(segment, "*"), segment, regex_string)

    build_regex_string(remaining_segments, new_regex_string)
  end

  defp build_regex_segment_string(false, segment, regex_string),
    do: regex_string <> segment <> "\\/"

  defp build_regex_segment_string(true, segment, regex_string) do
    parts_no_stars = String.split(segment, "*")
    parts = insert_stars(parts_no_stars, [])
    expression = build_regex_segment_string_wildcards(parts, "")
    regex_string <> expression <> "\\/"
  end

  defp insert_stars([], parts_with_stars), do: parts_with_stars

  defp insert_stars([part | remaining_parts], parts_with_stars) do
    new_parts_with_stars = insert_stars_not_last(part, remaining_parts, parts_with_stars)
    insert_stars(remaining_parts, new_parts_with_stars)
  end

  defp insert_stars_not_last(part, [], parts_with_stars), do: parts_with_stars ++ [part]
  defp insert_stars_not_last(part, _, parts_with_stars), do: parts_with_stars ++ [part, "*"]

  defp build_regex_segment_string_wildcards([], expression), do: expression

  defp build_regex_segment_string_wildcards(["*" | remaining_parts], expression),
    do: build_regex_segment_string_wildcards(remaining_parts, expression <> ".*")

  defp build_regex_segment_string_wildcards([part | remaining_parts], expression),
    do: build_regex_segment_string_wildcards(remaining_parts, expression <> part)

  defp get_connection() do
    {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/cloud-platform")
    GoogleApi.Storage.V1.Connection.new(token.token)
  end

  defp output_help_text() do
    IO.puts("sdlti_cli_tool")
    IO.puts("\r\nCommand line utility to perform various tasks for the Scalable Data LTI")
    IO.puts("\r\nCore arguments:")

    IO.puts("   --mode|-m <mode> (required)")

    IO.puts(
      "      getStats:        Create csv files from each of the stats Kafka topics, output summary file."
    )

    IO.puts("      copyBucket:      Copy objects from one gcs bucket to another")
    IO.puts("      getObjectInfo:   Print info about selected gcs objects from a gcs bucket")
    IO.puts("      tdmsLocal:       Process local TDMS file")
    IO.puts("      uploadDircetory: Upload/clone N times a directory of files to a GCS bucket")
    IO.puts("   --help|-h (optional)")
    IO.puts("\r\nMode <getStats> arguments:")

    IO.puts(
      "   {bq_table_root, :string, :required} {output_file_suffix, :string, :required} {working_directory, :string, :optional} --file_mode|-f"
    )

    IO.puts(
      "      bq_table_root:           the BQ tables suffix string/Kafka topic suffix string (e.g. barcelona_mfg)"
    )

    IO.puts(
      "      output_file_suffix:      output file suffix (e.g. ingest-phase-1-stats.<suffix>.csv"
    )

    IO.puts("      working_directory:       where to put/read csv files etc., defaults to './'")

    IO.puts("\r\nMode <copyBucket> arguments:")

    IO.puts(
      "   {source_bucket, :string, :required} {source_object_specifier, :string, :required} {target_bucket, :string, :required}, {destination_root, :string, {}:optional, default: <root>}} --preview|-p"
    )

    IO.puts(
      "      source_bucket:           name of the gcs bucket you wish to copy from (eg. my-bucket)"
    )

    IO.puts(
      "      source_object_specifier: specifies a pattern for the objects you wish to copy, with '*' wildcards allowed (eg. /exp1/cameraData/*.tdms)"
    )

    IO.puts(
      "      target_bucket:           name of the gcs bucket you wish to copy to (eg. my-other-bucket)"
    )

    IO.puts(
      "      destination_root:        prefix for destination names (eg. copy from /exp1/item.tdms to <destination_root>/exp1/item.tdms)"
    )

    IO.puts(
      "      --preview|-p             prints the list of objects to be copied but does not perform the copy, defaults to false"
    )

    IO.puts("\r\nMode <getObjectInfo> arguments:")

    IO.puts(
      "   {source_bucket, :string, :required} {source_object_specifier, :string, :required} --verbose|-v"
    )

    IO.puts(
      "      source_bucket:           name of the gcs bucket you wish to get object info from (eg. my-bucket)"
    )

    IO.puts(
      "      source_object_specifier: specifies a pattern for the objects you wish to inspect, with '*' wildcards allowed (eg. /exp1/cameraData/*.tdms)"
    )

    IO.puts(
      "      --verbose|-v             output complete object info rather than a synopsis, defaults to false"
    )

    IO.puts("\r\nMode <tdmsLocal> arguments:")
    IO.puts("   {tdms_file, :string, :required} {output_path, :string, :optional}")

    IO.puts(
      "      tdms_file:               full path of the source TDMS file (i.e. \"./foo.tdms\""
    )

    IO.puts(
      "      output_path:             specifies where to generate the channel files; if not specified, the directory containing the source TDMS file will be used"
    )

    IO.puts("\r\nMode <uploadDirectory> arguments:")

    IO.puts(
      "   [--repeat <count>] {source_directory, :string, :required} {destination_bucket, :string, :required} {destination_root, :string, :required}"
    )

    IO.puts(
      "      source_directory:        full path of the source directory, all files in the directory tree will be uploaded"
    )

    IO.puts(
      "      destination_bucket:      name of the gcs bucket to upload to (env var GOOGLE_APPLICATION_CREDENTIALS must point to a valid oauth token file granting access)"
    )

    IO.puts(
      "      destination_root:        prefix for destination object names, the remainder of the object name comes from the source file name"
    )

    IO.puts(
      "      --repeat <count>:        (optional) if specified, the contents of the source directory will be sent along with <count> clones."
    )

    :ok
  end
end
