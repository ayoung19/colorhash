# colorhash

[![Package Version](https://img.shields.io/hexpm/v/colorhash)](https://hex.pm/packages/colorhash)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/colorhash/)

Generate deterministic colors from strings - perfect for user avatars, data visualization, and category coloring.

```sh
gleam add colorhash@1
```

## Demo

🎨 **[Try the interactive demo](https://www.andyluyoung.com/colorhash/)**

## Usage

### Quick Start

```gleam
import colorhash
import gleam_community/colour

pub fn main() {
  let hasher = colorhash.new()
  let assert Ok(color) = colorhash.to_color(hasher, "hello@example.com")

  colour.to_hsla(color)
  // -> #(0.3988995873452545, 0.35, 0.5, 1.0)

  colour.to_rgba(color)
  // -> #(0.32499999999999996, 0.675, 0.4626891334250345, 1.0)

  colour.to_rgb_hex_string(color)
  // -> "53AC76"
}
```

### Custom Saturation

Control color intensity with custom saturation values:

```gleam
// Grayscale only
let gray_hasher =
  colorhash.new()
  |> colorhash.with_saturations([0.0])

// Vivid colors only
let vivid_hasher =
  colorhash.new()
  |> colorhash.with_saturations([0.8, 0.9, 1.0])
```

### Custom Lightness

Adjust brightness for different themes:

```gleam
// Dark theme colors
let dark_hasher =
  colorhash.new()
  |> colorhash.with_lightnesses([0.2, 0.3, 0.4])

// Light theme colors
let light_hasher =
  colorhash.new()
  |> colorhash.with_lightnesses([0.7, 0.8, 0.9])
```

### Custom Hue Ranges

Constrain colors to specific ranges:

```gleam
// Warm colors only (reds, oranges, yellows)
let warm_hasher =
  colorhash.new()
  |> colorhash.with_hue_ranges([#(0.0, 0.17)])

// Cool colors only (blues, greens)
let cool_hasher =
  colorhash.new()
  |> colorhash.with_hue_ranges([#(0.33, 0.67)])

// Multiple distinct ranges
let brand_hasher =
  colorhash.new()
  |> colorhash.with_hue_ranges([
    #(0.0, 0.1),   // Reds
    #(0.55, 0.65), // Blues
  ])
```

### Custom Hash Function

Use a different hash function for special requirements:

```gleam
import gleam/string

// Simple hash based on string length
let length_hasher =
  colorhash.new()
  |> colorhash.with_hash_fun(string.length)
```

Further documentation can be found at <https://hexdocs.pm/colorhash>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
