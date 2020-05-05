defmodule Sdlti do
  @moduledoc """
  Documentation for Sdlti.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Sdlti.hello()
      :world

  """
  def hello do
    :world
  end

  def clone_file_n_times(path, clone_count) do
    {base_path, dotted_ext} = strip_extension(path, Path.extname(path))
    clone_file_n_times(1..clone_count, path, base_path, dotted_ext)
    :ok
  end

  defp clone_file_n_times(range, source, base_path, ext_name) do
    for number <- range do
      File.cp(source, base_path <> "_#{number}" <> ext_name)
    end
  end

  defp strip_extension(path, ""), do: {path, ""}
  defp strip_extension(path, ext), do: {String.trim_trailing(path, ext), ext}
end
