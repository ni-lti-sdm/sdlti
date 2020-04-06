defmodule Sdlti.MixProject do
  use Mix.Project

  def project do
    [
      app: :sdlti,
      version: "0.0.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Commandline.CLI],
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :goth]
    ]
  end

  defp deps() do
    [
      {:flow, "~> 1.0.0"},
      {:google_api_storage, "~> 0.17.0"},
      {:tdms_to_channels, git: "https://github.com/msw10100/tdms-to-channels.git"},
      {:goth, "~> 1.2.0"}
    ]
  end
end
