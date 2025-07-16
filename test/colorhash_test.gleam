import colorhash
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam_community/colour
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// Core algorithm consistency tests
pub fn determinism_test() {
  let hasher = colorhash.new()
  let color1 = colorhash.to_color(hasher, "test")
  let color2 = colorhash.to_color(hasher, "test")
  let color3 = colorhash.to_color(hasher, "test")

  assert color1 == color2
  assert color2 == color3
}

// Test different inputs produce different colors
pub fn different_inputs_test() {
  let hasher = colorhash.new()
  let inputs = ["a", "b", "c", "d", "e", "f", "g", "h"]

  let colors =
    inputs
    |> list.map(fn(input) {
      let assert Ok(color) = colorhash.to_color(hasher, input)
      color
    })

  let unique_count = list.unique(colors) |> list.length
  assert unique_count >= 6
}

// Empty configuration tests
pub fn empty_saturations_fallback_test() {
  let hasher_default = colorhash.new()
  let hasher_empty = colorhash.new() |> colorhash.with_saturations([])

  let assert Ok(color_default) = colorhash.to_color(hasher_default, "test")
  let assert Ok(color_empty) = colorhash.to_color(hasher_empty, "test")

  assert color_default == color_empty
}

pub fn empty_lightnesses_fallback_test() {
  let hasher_default = colorhash.new()
  let hasher_empty = colorhash.new() |> colorhash.with_lightnesses([])

  let assert Ok(color_default) = colorhash.to_color(hasher_default, "test")
  let assert Ok(color_empty) = colorhash.to_color(hasher_empty, "test")

  assert color_default == color_empty
}

pub fn empty_hue_ranges_fallback_test() {
  let hasher_default = colorhash.new()
  let hasher_empty = colorhash.new() |> colorhash.with_hue_ranges([])

  let assert Ok(color_default) = colorhash.to_color(hasher_default, "test")
  let assert Ok(color_empty) = colorhash.to_color(hasher_empty, "test")

  assert color_default == color_empty
}

// Test all empty configurations together
pub fn all_empty_configurations_test() {
  let hasher_default = colorhash.new()
  let hasher_all_empty =
    colorhash.new()
    |> colorhash.with_saturations([])
    |> colorhash.with_lightnesses([])
    |> colorhash.with_hue_ranges([])

  let assert Ok(color_default) = colorhash.to_color(hasher_default, "test")
  let assert Ok(color_empty) = colorhash.to_color(hasher_all_empty, "test")

  assert color_default == color_empty
}

// Configuration value tests
pub fn single_saturation_test() {
  let hasher = colorhash.new() |> colorhash.with_saturations([0.7])

  // Test with many inputs to ensure consistency
  list.range(0, 50)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(_, s, _, _) = colour.to_hsla(color)
    assert s == 0.7
  })
}

pub fn single_lightness_test() {
  let hasher = colorhash.new() |> colorhash.with_lightnesses([0.3])

  // Test with many inputs to ensure consistency
  list.range(0, 50)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(_, _, l, _) = colour.to_hsla(color)
    assert l == 0.3
  })
}

pub fn single_hue_range_test() {
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.2, 0.3)])

  // Test with 100 different inputs to ensure consistency
  list.range(0, 100)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(h, _, _, _) = colour.to_hsla(color)
    assert h >=. 0.2 && h <=. 0.3
  })
}

// Multiple configuration values distribution
pub fn multiple_saturations_distribution_test() {
  let saturations = [0.2, 0.5, 0.8]
  let hasher = colorhash.new() |> colorhash.with_saturations(saturations)

  let results =
    list.range(0, 30)
    |> list.map(fn(i) {
      let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
      let #(_, s, _, _) = colour.to_hsla(color)
      s
    })

  // Check all configured saturations are used
  list.each(saturations, fn(expected_s) {
    assert list.contains(results, expected_s)
  })
}

pub fn multiple_lightnesses_distribution_test() {
  let lightnesses = [0.2, 0.5, 0.8]
  let hasher = colorhash.new() |> colorhash.with_lightnesses(lightnesses)

  let results =
    list.range(0, 30)
    |> list.map(fn(i) {
      let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
      let #(_, _, l, _) = colour.to_hsla(color)
      l
    })

  // Check all configured lightnesses are used
  list.each(lightnesses, fn(expected_l) {
    assert list.contains(results, expected_l)
  })
}

// Edge case HSL values
pub fn saturation_zero_test() {
  // Saturation 0 should produce grayscale colors
  let hasher = colorhash.new() |> colorhash.with_saturations([0.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(_, s, _, _) = colour.to_hsla(color)
  assert s == 0.0

  // With zero saturation, RGB values should be equal (grayscale)
  let #(r, g, b, _) = colour.to_rgba(color)
  assert float.loosely_equals(r, g, 1.0)
  assert float.loosely_equals(g, b, 1.0)
}

pub fn saturation_one_test() {
  // Saturation 1.0 should produce fully saturated colors
  let hasher = colorhash.new() |> colorhash.with_saturations([1.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(_, s, _, _) = colour.to_hsla(color)
  assert s == 1.0
}

pub fn lightness_zero_test() {
  // Lightness 0 should produce black
  let hasher = colorhash.new() |> colorhash.with_lightnesses([0.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(_, _, l, _) = colour.to_hsla(color)
  assert l == 0.0

  // Should be black
  let hex = colour.to_rgb_hex_string(color)
  assert hex == "000000"
}

pub fn lightness_one_test() {
  // Lightness 1.0 should produce white
  let hasher = colorhash.new() |> colorhash.with_lightnesses([1.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(_, _, l, _) = colour.to_hsla(color)
  assert l == 1.0

  // Should be white
  let hex = colour.to_rgb_hex_string(color)
  assert hex == "FFFFFF"
}

// Invalid HSL values tests
pub fn negative_saturation_test() {
  let hasher = colorhash.new() |> colorhash.with_saturations([-0.5])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn saturation_greater_than_one_test() {
  let hasher = colorhash.new() |> colorhash.with_saturations([1.5])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn negative_lightness_test() {
  let hasher = colorhash.new() |> colorhash.with_lightnesses([-0.5])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn lightness_greater_than_one_test() {
  let hasher = colorhash.new() |> colorhash.with_lightnesses([1.5])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn negative_hue_range_start_test() {
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(-0.1, 0.5)])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn hue_range_end_greater_than_one_test() {
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.5, 1.5)])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn negative_hue_range_end_test() {
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.0, -0.5)])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn multiple_invalid_values_test() {
  // Test with multiple invalid values at once
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([-0.5, 1.5, 0.5])
    // Two invalid values
    |> colorhash.with_lightnesses([0.3, 2.0])
    // One invalid value
    |> colorhash.with_hue_ranges([#(-0.1, 0.5), #(0.6, 1.2)])
  // Two invalid values

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

pub fn boundary_values_valid_test() {
  // Test that 0.0 and 1.0 are accepted as valid values
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([0.0, 1.0])
    |> colorhash.with_lightnesses([0.0, 1.0])
    |> colorhash.with_hue_ranges([#(0.0, 1.0)])

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_ok
}

pub fn inverted_hue_range_test() {
  // Start > End should still work (swapped)
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.8, 0.2)])

  // Test with multiple inputs to ensure swapping works consistently
  list.range(0, 50)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(h, _, _, _) = colour.to_hsla(color)
    // Hue should be in the swapped range
    assert h >=. 0.2 && h <=. 0.8
  })
}

// Hash function tests
pub fn custom_hash_constant_test() {
  let hasher = colorhash.new() |> colorhash.with_hash_fun(fn(_) { 42 })

  let assert Ok(color1) = colorhash.to_color(hasher, "input1")
  let assert Ok(color2) = colorhash.to_color(hasher, "input2")
  let assert Ok(color3) = colorhash.to_color(hasher, "different")

  assert color1 == color2
  assert color2 == color3
}

pub fn custom_hash_zero_test() {
  let hasher = colorhash.new() |> colorhash.with_hash_fun(fn(_) { 0 })

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(h, s, l, _) = colour.to_hsla(color)

  // With hash 0, should select first values
  assert h == 0.0
  // First hue range is (0.0, 1.0), 0 % 727 = 0
  assert s == 0.35
  // First saturation
  assert l == 0.35
  // First lightness
}

// Large hash value tests
pub fn large_hash_values_test() {
  let large_values = [
    2_147_483_647,
    // Max int32
    1_000_000_000,
    // Large round number
    4_294_967_295,
    // Max uint32
  ]

  list.each(large_values, fn(hash_value) {
    let hasher =
      colorhash.new() |> colorhash.with_hash_fun(fn(_) { hash_value })
    let res = colorhash.to_color(hasher, "test")
    assert res |> result.is_ok
  })
}

// Edge case string inputs
pub fn empty_string_input_test() {
  let hasher = colorhash.new()
  let res = colorhash.to_color(hasher, "")
  assert res |> result.is_ok
}

pub fn very_long_string_input_test() {
  let long_string = list.repeat("a", 10_000) |> string.join("")
  let hasher = colorhash.new()
  let res = colorhash.to_color(hasher, long_string)
  assert res |> result.is_ok
}

pub fn unicode_string_input_test() {
  let unicode_strings = ["🌈", "你好", "مرحبا", "🎨🖌️"]
  let hasher = colorhash.new()

  list.each(unicode_strings, fn(input) {
    let res = colorhash.to_color(hasher, input)
    assert res |> result.is_ok
  })
}

// Configuration consistency tests
pub fn default_values_test() {
  let hasher = colorhash.new()

  // Test with known hash to verify default values
  let hasher_with_hash = hasher |> colorhash.with_hash_fun(fn(_) { 0 })
  let assert Ok(color) = colorhash.to_color(hasher_with_hash, "test")
  let #(_, s, l, _) = colour.to_hsla(color)

  assert s == 0.35
  // First default saturation
  assert l == 0.35
  // First default lightness
}

pub fn chained_configuration_test() {
  // Test that chaining configurations works correctly
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([0.9])
    |> colorhash.with_lightnesses([0.1])
    |> colorhash.with_hue_ranges([#(0.5, 0.6)])

  // Test with multiple inputs
  list.range(0, 30)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(h, s, l, _) = colour.to_hsla(color)
    assert s == 0.9
    assert l == 0.1
    assert h >=. 0.5 && h <=. 0.6
  })
}

// Hue range special cases
pub fn zero_width_hue_range_test() {
  // Hue range where start == end
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.5, 0.5)])

  // Test many inputs to ensure it always returns the exact value
  list.range(0, 50)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(h, _, _, _) = colour.to_hsla(color)
    assert h == 0.5
  })
}

pub fn full_hue_range_test() {
  // Full range should allow all hues
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.0, 1.0)])

  // Test with more samples for better statistical confidence
  let hues =
    list.range(0, 200)
    |> list.map(fn(i) {
      let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
      let #(h, _, _, _) = colour.to_hsla(color)
      h
    })

  // Should have good distribution across full range
  let unique_hues = list.unique(hues) |> list.length
  assert unique_hues >= 150
  // Expect at least 75% unique values

  // Verify all hues are within valid range
  list.each(hues, fn(h) {
    assert h >=. 0.0 && h <=. 1.0
  })
}

// Multiple hue ranges test
pub fn multiple_hue_ranges_test() {
  let ranges = [#(0.0, 0.2), #(0.4, 0.6), #(0.8, 1.0)]
  let hasher = colorhash.new() |> colorhash.with_hue_ranges(ranges)

  // Test with more samples to ensure proper distribution
  let hues =
    list.range(0, 100)
    |> list.map(fn(i) {
      let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
      let #(h, _, _, _) = colour.to_hsla(color)
      h
    })

  // All hues should fall within one of the ranges
  list.each(hues, fn(h) {
    let in_range =
      list.any(ranges, fn(range) {
        let #(start, end) = range
        h >=. start && h <=. end
      })
    assert in_range
  })

  // Also verify that we actually use all ranges (not just one)
  let range_usage =
    list.map(ranges, fn(range) {
      let #(start, end) = range
      list.any(hues, fn(h) { h >=. start && h <=. end })
    })
  assert list.all(range_usage, fn(used) { used })
}

// Extreme configuration combinations
pub fn all_zero_configuration_test() {
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([0.0])
    |> colorhash.with_lightnesses([0.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let hex = colour.to_rgb_hex_string(color)
  assert hex == "000000"
  // Should be black
}

pub fn all_one_configuration_test() {
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([1.0])
    |> colorhash.with_lightnesses([1.0])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let hex = colour.to_rgb_hex_string(color)
  assert hex == "FFFFFF"
  // Should be white
}

// Saturation and lightness 0.5 tests
pub fn neutral_gray_test() {
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([0.0])
    |> colorhash.with_lightnesses([0.5])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let hex = colour.to_rgb_hex_string(color)
  assert hex == "808080"
  // Should be middle gray
}

// Hash collision behavior
pub fn hash_distribution_quality_test() {
  let hasher = colorhash.new()

  // Generate colors for sequential inputs
  let colors =
    list.range(0, 100)
    |> list.map(fn(i) {
      let assert Ok(color) =
        colorhash.to_color(hasher, "user" <> int.to_string(i))
      colour.to_rgb_hex_string(color)
    })

  // Should have good distribution
  let unique_colors = list.unique(colors) |> list.length
  assert unique_colors >= 80
  // At least 80% unique colors
}

// Configuration override tests
pub fn saturation_override_test() {
  let hasher1 =
    colorhash.new()
    |> colorhash.with_saturations([0.5])
    |> colorhash.with_saturations([0.8])
  // Should override

  let assert Ok(color) = colorhash.to_color(hasher1, "test")
  let #(_, s, _, _) = colour.to_hsla(color)
  assert s == 0.8
}

pub fn lightness_override_test() {
  let hasher1 =
    colorhash.new()
    |> colorhash.with_lightnesses([0.5])
    |> colorhash.with_lightnesses([0.8])
  // Should override

  let assert Ok(color) = colorhash.to_color(hasher1, "test")
  let #(_, _, l, _) = colour.to_hsla(color)
  assert l == 0.8
}

pub fn hue_range_override_test() {
  let hasher1 =
    colorhash.new()
    |> colorhash.with_hue_ranges([#(0.0, 0.5)])
    |> colorhash.with_hue_ranges([#(0.5, 1.0)])
  // Should override

  // Test multiple inputs to ensure override works consistently
  list.range(0, 30)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher1, int.to_string(i))
    let #(h, _, _, _) = colour.to_hsla(color)
    assert h >=. 0.5
  })
}

// Edge case with many configuration values
pub fn many_saturations_test() {
  let saturations =
    list.range(1, 10)
    |> list.map(fn(i) { int.to_float(i) /. 10.0 })
  let hasher = colorhash.new() |> colorhash.with_saturations(saturations)

  // Should be able to handle many values
  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_ok
}

pub fn many_lightnesses_test() {
  let lightnesses =
    list.range(1, 10)
    |> list.map(fn(i) { int.to_float(i) /. 10.0 })
  let hasher = colorhash.new() |> colorhash.with_lightnesses(lightnesses)

  // Should be able to handle many values
  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_ok
}

pub fn many_hue_ranges_test() {
  let ranges =
    list.range(0, 9)
    |> list.map(fn(i) {
      let start = int.to_float(i) /. 10.0
      let end = int.to_float(i + 1) /. 10.0
      #(start, end)
    })
  let hasher = colorhash.new() |> colorhash.with_hue_ranges(ranges)

  // Should be able to handle many ranges
  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_ok
}

// Test negative hash values
pub fn negative_hash_value_test() {
  let hasher = colorhash.new() |> colorhash.with_hash_fun(fn(_) { -42 })

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_ok
}

// Test hash function that returns 0
pub fn zero_hash_all_configs_test() {
  let hasher =
    colorhash.new()
    |> colorhash.with_hash_fun(fn(_) { 0 })
    |> colorhash.with_saturations([0.1, 0.2, 0.3])
    |> colorhash.with_lightnesses([0.4, 0.5, 0.6])
    |> colorhash.with_hue_ranges([#(0.1, 0.2), #(0.3, 0.4)])

  let assert Ok(color) = colorhash.to_color(hasher, "any_input")
  let #(h, s, l, _) = colour.to_hsla(color)

  // With hash 0, should always select first elements
  assert s == 0.1
  // First saturation
  assert l == 0.4
  // First lightness
  assert h >=. 0.1 && h <=. 0.2
  // First hue range
}

// Test very small hue ranges
pub fn tiny_hue_range_test() {
  let hasher = colorhash.new() |> colorhash.with_hue_ranges([#(0.5, 0.50001)])

  list.range(0, 20)
  |> list.each(fn(i) {
    let assert Ok(color) = colorhash.to_color(hasher, int.to_string(i))
    let #(h, _, _, _) = colour.to_hsla(color)
    assert h >=. 0.5 && h <=. 0.50001
  })
}

// Test mixed valid and invalid configurations
pub fn partial_invalid_config_test() {
  // Even if some values are valid, any invalid value should cause error
  let hasher =
    colorhash.new()
    |> colorhash.with_saturations([0.5, 0.7, -0.1])
  // One invalid

  let res = colorhash.to_color(hasher, "test")
  assert res |> result.is_error
}

// Test exact boundary calculations
pub fn exact_boundary_hue_test() {
  let hasher =
    colorhash.new()
    |> colorhash.with_hash_fun(fn(_) { 726 })
    // Just before hue_resolution
    |> colorhash.with_hue_ranges([#(0.0, 1.0)])

  let assert Ok(color) = colorhash.to_color(hasher, "test")
  let #(h, _, _, _) = colour.to_hsla(color)

  // h should be very close to 1.0 but not quite
  assert h >. 0.99 && h <. 1.0
}
