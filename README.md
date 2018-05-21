# MrNoisy

Pulls open merge request list from gitlab and lists them on a messaging client (i.e. Slack).

## Usage

Set the required environment variables: `SLACK_TOKEN`, `CHANNEL` and `GITLAB_TOKEN`.
```
iex -S mix
MrNoisy.do_it
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `mr_noisy` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mr_noisy, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/mr_noisy](https://hexdocs.pm/mr_noisy).

