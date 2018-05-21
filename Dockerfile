FROM elixir:latest
LABEL MAINTAINER "Raphael Tan <raphaeltanyw@gmail.com>"

WORKDIR /usr/app

COPY . /usr/app

RUN mix local.hex --force
RUN mix deps.get