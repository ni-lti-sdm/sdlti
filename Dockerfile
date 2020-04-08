FROM elixir:1.10-alpine as build

# install build dependencies
RUN apk add --update git build-base nodejs npm yarn python openssh

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

ENV SECRET_KEY_BASE=6v+LKpr/9fjcvPUUTEH5syAyMptcOds9P1dCnAYaWlv7dZn48Nchk5004OFw0/NJ

ARG SSH_KEY_B64
ENV SSH_KEY_B64=${SSH_KEY_B64}

RUN mkdir /root/.ssh
RUN echo $SSH_KEY_B64 >> /root/.ssh/id_rsa.b64
RUN echo $SSH_KEY_B64
RUN base64 -d ~/.ssh/id_rsa.b64 > ~/.ssh/id_rsa
RUN echo `cat ~/.ssh/id_rsa`
RUN chmod 600 ~/.ssh/id_rsa
RUN ssh-keyscan -H github.com >> ~/.ssh/known_hosts

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY test test

RUN cat ~/.ssh/id_rsa

RUN mix deps.get
RUN mix deps.compile

# build project
RUN mix compile

# run tests
RUN mix test

# build/install/run CLI image
RUN mix escript.build
RUN mix escript.install --force
RUN ~/.mix/escripts/sdlti
