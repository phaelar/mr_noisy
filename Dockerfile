FROM elixir:alpine
LABEL MAINTAINER "Raphael Tan <raphaeltanyw@gmail.com>"

WORKDIR /usr/app

COPY . /usr/app

RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix deps.get
RUN mix deps.compile

CMD [ "mix", "run", "lib/mr_noisy.exs" ]