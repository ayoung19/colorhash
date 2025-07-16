//// A library for generating deterministic colors from strings.
////
//// This library allows you to generate consistent, visually distinct colors
//// from any string input. The same string will always produce the same color,
//// making it perfect for generating colors for user avatars, data visualization,
//// category coloring, or any use case where you need consistent colors without
//// manually assigning them.
////
//// ## Basic Usage
////
//// ```gleam
//// import colorhash
//// import gleam_community/colour
////
//// let hasher = colorhash.new()
//// let assert Ok(color) = colorhash.to_color(hasher, "hello@example.com")
//// 
//// // Convert to hex for use in HTML/CSS
//// let hex = colour.to_rgb_hex_string(color)
//// // -> "53AC76"
//// ```

import gleam/bit_array
import gleam/bool
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam_community/colour.{type Color}

fn sha256(s: String) -> Int {
  let assert <<hash:32, _:bits>> =
    crypto.hash(crypto.Sha256, bit_array.from_string(s))

  hash
}

/// An opaque type that holds the configuration for generating colors.
///
/// The ColorHash type contains:
/// - A list of possible saturation values
/// - A list of possible lightness values  
/// - A list of hue ranges to constrain generated colors
/// - A hash function to convert strings to integers
pub opaque type ColorHash {
  ColorHash(
    saturations: Dict(Int, Float),
    lightnesses: Dict(Int, Float),
    hue_ranges: Dict(Int, #(Float, Float)),
    hash_fun: fn(String) -> Int,
  )
}

/// Creates a new ColorHash with default configuration.
///
/// The default configuration provides a good balance of color variety and
/// visual appeal for most use cases.
///
/// ## Default Values
///
/// - **Saturations**: `[0.35, 0.5, 0.65]` - Moderately saturated colors
/// - **Lightnesses**: `[0.35, 0.5, 0.65]` - Medium brightness range  
/// - **Hue ranges**: `[#(0.0, 1.0)]` - Full color spectrum
/// - **Hash function**: SHA256 (cryptographically secure, good distribution)
///
/// ## Examples
///
/// ```gleam
/// let hasher = colorhash.new()
/// ```
///
pub fn new() -> ColorHash {
  ColorHash(
    saturations: [0.35, 0.5, 0.65]
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
    lightnesses: [0.35, 0.5, 0.65]
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
    hue_ranges: [#(0.0, 1.0)]
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
    hash_fun: sha256,
  )
}

/// Sets the list of possible saturation values for generated colors.
///
/// Saturation controls the intensity or purity of a color. 
/// - `0.0` produces grayscale (no color)
/// - `1.0` produces fully saturated (pure) colors
///
/// ## Parameters
///
/// - `color_hash`: The ColorHash to update
/// - `saturations`: List of saturation values, each must be in range `[0.0, 1.0]`
///
/// ## Behavior
///
/// - The hash value determines which saturation is selected from the list
/// - An empty list will cause the default saturations `[0.35, 0.5, 0.65]` to be used
/// - Values outside `[0.0, 1.0]` will cause `to_color` to return an error
///
/// ## Examples
///
/// ```gleam
/// // Grayscale only
/// let gray_hasher = 
///   colorhash.new()
///   |> colorhash.with_saturations([0.0])
///
/// // Vivid colors only  
/// let vivid_hasher =
///   colorhash.new()
///   |> colorhash.with_saturations([0.8, 0.9, 1.0])
///
/// // Fixed saturation
/// let fixed_hasher =
///   colorhash.new()
///   |> colorhash.with_saturations([0.7])
/// ```
///
pub fn with_saturations(
  color_hash: ColorHash,
  saturations: List(Float),
) -> ColorHash {
  ColorHash(
    ..color_hash,
    saturations: saturations
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
  )
}

/// Sets the list of possible lightness values for generated colors.
///
/// Lightness controls the brightness of a color.
/// - `0.0` produces black
/// - `0.5` produces pure color
/// - `1.0` produces white
///
/// ## Parameters
///
/// - `color_hash`: The ColorHash to update
/// - `lightnesses`: List of lightness values, each must be in range `[0.0, 1.0]`
///
/// ## Behavior
///
/// - The hash value determines which lightness is selected from the list
/// - An empty list will cause the default lightnesses `[0.35, 0.5, 0.65]` to be used
/// - Values outside `[0.0, 1.0]` will cause `to_color` to return an error
///
/// ## Examples
///
/// ```gleam
/// // Dark theme colors
/// let dark_hasher =
///   colorhash.new()
///   |> colorhash.with_lightnesses([0.2, 0.3, 0.4])
///
/// // Light theme colors
/// let light_hasher =
///   colorhash.new()
///   |> colorhash.with_lightnesses([0.7, 0.8, 0.9])
///
/// // High contrast (black or white tendency)
/// let contrast_hasher =
///   colorhash.new()
///   |> colorhash.with_lightnesses([0.1, 0.9])
/// ```
///
pub fn with_lightnesses(
  color_hash: ColorHash,
  lightnesses: List(Float),
) -> ColorHash {
  ColorHash(
    ..color_hash,
    lightnesses: lightnesses
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
  )
}

/// Sets the list of hue ranges to constrain generated colors.
///
/// Hue determines the base color on the color wheel.
/// - `0.0` = Red
/// - `0.33` ≈ Green  
/// - `0.67` ≈ Blue
/// - `1.0` = Red (wraps back)
///
/// ## Parameters
///
/// - `color_hash`: The ColorHash to update
/// - `hue_ranges`: List of tuples `#(start, end)` where both values must be in `[0.0, 1.0]`
///
/// ## Behavior
///
/// - The hash value determines which hue range is selected from the list
/// - Within the selected range, the hash determines the exact hue value
/// - An empty list will cause the default range `[#(0.0, 1.0)]` to be used
/// - Values outside `[0.0, 1.0]` will cause `to_color` to return an error
///
/// ## Range Behavior
///
/// - **Normal ranges**: When `start < end`, hues are generated between start and end
/// - **Inverted ranges**: When `start > end`, the range is treated as swapped (e.g., `#(0.8, 0.2)` generates hues between 0.2 and 0.8)
/// - **Zero-width ranges**: When `start == end`, all generated hues will be exactly that value
///
/// ## Examples
///
/// ```gleam
/// // Warm colors only (reds, oranges, yellows)
/// let warm_hasher =
///   colorhash.new()
///   |> colorhash.with_hue_ranges([#(0.0, 0.17)])
///
/// // Cool colors only (blues, greens)
/// let cool_hasher =
///   colorhash.new()
///   |> colorhash.with_hue_ranges([#(0.33, 0.67)])
///
/// // Multiple distinct ranges
/// let multi_hasher =
///   colorhash.new()
///   |> colorhash.with_hue_ranges([
///     #(0.0, 0.1),   // Reds
///     #(0.3, 0.4),   // Greens
///     #(0.6, 0.7),   // Blues
///   ])
/// ```
///
pub fn with_hue_ranges(
  color_hash: ColorHash,
  hue_ranges: List(#(Float, Float)),
) -> ColorHash {
  ColorHash(
    ..color_hash,
    hue_ranges: hue_ranges
      |> list.index_map(fn(x, i) { #(i, x) })
      |> dict.from_list,
  )
}

/// Sets a custom hash function for converting strings to integers.
///
/// The hash function determines how input strings are converted to numbers,
/// which affects the color distribution and randomness.
///
/// ## Parameters
///
/// - `color_hash`: The ColorHash to update
/// - `hash_fun`: A function that takes a String and returns an Int
///
/// ## Behavior
///
/// - The default hash function uses SHA256 for cryptographically secure, well-distributed values
/// - Custom hash functions can be used for different distributions or performance characteristics
/// - Negative hash values are automatically converted to positive using absolute value
/// - The same input string should always produce the same hash value for deterministic colors
///
/// ## Examples
///
/// ```gleam
/// // Use a simple sum of character codes (less random but faster)
/// let simple_hasher =
///   colorhash.new()
///   |> colorhash.with_hash_fun(fn(s) {
///     s
///     |> string.to_utf_codepoints
///     |> list.map(string.utf_codepoint_to_int)
///     |> list.fold(0, int.add)
///   })
///
/// // Use a constant for testing
/// let test_hasher =
///   colorhash.new()
///   |> colorhash.with_hash_fun(fn(_) { 42 })
///
/// // Use string length (groups similar length strings)  
/// let length_hasher =
///   colorhash.new()
///   |> colorhash.with_hash_fun(string.length)
/// ```
///
pub fn with_hash_fun(
  color_hash: ColorHash,
  hash_fun: fn(String) -> Int,
) -> ColorHash {
  ColorHash(..color_hash, hash_fun: hash_fun)
}

/// Generates a deterministic color from an input string.
///
/// This is the main function of the library. It takes a string input and
/// produces a color based on the ColorHash configuration. The same input
/// will always produce the same color.
///
/// ## Parameters
///
/// - `color_hash`: The configured ColorHash containing generation parameters
/// - `input`: Any string to convert to a color
///
/// ## Returns
///
/// - `Ok(Color)`: A color from the `gleam_community/colour` package
/// - `Error(Nil)`: If any configured values are outside the valid range `[0.0, 1.0]`
///
/// ## Behavior
///
/// - The hash value determines which saturation, lightness, and hue range are selected
/// - Empty configuration lists fall back to the default values
/// - Negative hash values are automatically converted to positive using absolute value
/// - Inverted hue ranges (where start > end) are treated as swapped ranges
/// - Unicode strings are fully supported
///
/// ## Error Cases
///
/// Returns `Error(Nil)` when:
/// - Any saturation value is outside `[0.0, 1.0]`
/// - Any lightness value is outside `[0.0, 1.0]`
/// - Any hue range start or end is outside `[0.0, 1.0]`
///
/// ## Examples
///
/// ```gleam
///
/// let hasher = colorhash.new()
/// let assert Ok(color) = colorhash.to_color(hasher, "hello@example.com")
/// 
/// // Convert to hex for use in HTML/CSS
/// let hex = colour.to_rgb_hex_string(color)
/// // -> "53AC76"
/// ```
///
pub fn to_color(color_hash: ColorHash, input: String) -> Result(Color, Nil) {
  let default_color_hash = new()
  let hue_ranges = case dict.size(color_hash.hue_ranges) {
    0 -> default_color_hash.hue_ranges
    _ -> color_hash.hue_ranges
  }
  let saturations = case dict.size(color_hash.saturations) {
    0 -> default_color_hash.saturations
    _ -> color_hash.saturations
  }
  let lightnesses = case dict.size(color_hash.lightnesses) {
    0 -> default_color_hash.lightnesses
    _ -> color_hash.lightnesses
  }

  let has_invalid_value =
    [
      hue_ranges
        |> dict.values
        |> list.flat_map(fn(x) {
          let #(start, end) = x
          [start, end]
        }),
      saturations |> dict.values,
      lightnesses |> dict.values,
    ]
    |> list.flatten
    |> list.any(fn(x) { x <. 0.0 || x >. 1.0 })

  use <- bool.guard(has_invalid_value, Error(Nil))

  let hash = int.absolute_value(color_hash.hash_fun(input))

  let hue_resolution = 727
  use #(hue_range_start, hue_range_end) <- result.try(dict.get(
    hue_ranges,
    hash % dict.size(hue_ranges),
  ))
  // TODO: As opposed to swapping the ranges if start > end, consider making it wrap around the bounds.
  let h =
    int.to_float({ hash / dict.size(hue_ranges) } % hue_resolution)
    *. float.absolute_value(hue_range_end -. hue_range_start)
    /. int.to_float(hue_resolution)
    +. float.min(hue_range_start, hue_range_end)
  use s <- result.try(dict.get(
    saturations,
    { hash / 360 } % dict.size(saturations),
  ))
  use l <- result.try(dict.get(
    lightnesses,
    { hash / 360 / dict.size(saturations) } % dict.size(lightnesses),
  ))

  colour.from_hsl(h, s, l)
}
