# colorhash

[![Package Version](https://img.shields.io/hexpm/v/colorhash)](https://hex.pm/packages/colorhash)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/colorhash/)

```sh
gleam add colorhash@1
```

```gleam
import colorhash

pub fn main() -> Nil {
  colorhash.new() |> colorhash.to_hsl("hello world")
  // -> #(188.1416781292985, 0.65, 0.65)

  colorhash.new() |> colorhash.to_rgb("hello world")
  // -> #(108, 208, 224)

  colorhash.new() |> colorhash.to_hex("hello world")
  // -> "#6CD0E0"
}
```

Further documentation can be found at <https://hexdocs.pm/colorhash>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
