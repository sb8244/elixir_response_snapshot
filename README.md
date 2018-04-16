# ResponseSnapshot

ResponseSnapshot is a testing tool for Elixir that captures the output of responses
and ensures that they do not change in between test runs. The output is saved to disk,
meant to be checked into source control, and can be used by frontend and other tests
to ensure proper integration between frontend and backend code.

## Disclaimer

This is in development. A version 1.0 will mark the public release.

## TODO

- [x] Setup desired testing interface
- [ ] Setup application option defaults
- [x] Compare JSON responses deeply
  - [x] value change doesn't fail mode (new / missing keys will fail)
  - [x] exact value mode (new / missing keys, changed values will fail)
- [ ] Compare HTML responses at face value
- [x] Fail tests with helpful message on failure
- [ ] Allow re-recording of a snapshot with a switch passed to the test suite

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `elixir_response_snapshot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:elixir_response_snapshot, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/elixir_response_snapshot](https://hexdocs.pm/elixir_response_snapshot).
