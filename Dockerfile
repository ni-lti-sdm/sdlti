FROM elixir:1.10-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

ENV SECRET_KEY_BASE=6v+LKpr/9fjcvPUUTEH5syAyMptcOds9P1dCnAYaWlv7dZn48Nchk5004OFw0/NJ

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY test test
RUN mix deps.get
RUN mix deps.compile

# build project
RUN mix compile

# run tests
RUN mix test

# build/install/run CLI image
RUN mix esccript.build
RUN mix escript.install --force
RUN ~/.mix/escripts/sdlti
