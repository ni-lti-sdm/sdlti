defmodule Sdlti.BatchMetadataBatchStats.GenConsumer do
  use KafkaEx.GenConsumer

  alias KafkaEx.Protocol.Fetch.Message

  require Logger

  # note - messages are delivered in batches
  def handle_message_set(message_set, state) do
    Logger.info(
      "[ingest-batch-metadata-batch-stats] message_set rcvd, size=#{Enum.count(message_set)}"
    )

    for %Message{value: message} <- message_set do
      {:ok, decoded_message} = Jason.decode(message)

      Logger.info(
        "[ingest-batch-metadata-batch-stats] decoded_message=#{inspect(decoded_message)}"
      )
    end

    count = Enum.count(message_set)
    Counter.received(count)
    the_end = System.monotonic_time(:second)

    Logger.info(
      "[ingest-batch-metadata-batch-stats] message_set done, count=#{Enum.count(message_set)}"
    )

    {:async_commit, state}
  end
end
