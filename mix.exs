defmodule Sdlti.MixProject do
  use Mix.Project

  def project do
    [
      app: :sdlti,
      version: "0.0.1",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Commandline.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :goth, :runtime_tools, :kafka_ex]
    ]
  end

  defp deps() do
    [
      {:flow, "~> 1.0.0"},
      {:google_api_storage, "~> 0.17.0"},
      {:goth, "~> 1.2.0"},
      {:jason, "~> 1.2"},
      {:kafka_ex, git: "https://github.com/ni-lti-sdm/kafka_ex.git"},
      {:tdms_to_channels, git: "git@github.com:msw10100/tdms-to-channels.git"}
    ]
  end
end
