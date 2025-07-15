import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam_community/colour.{type Color}

pub type ColorHash {
  ColorHash(
    saturations: Dict(Int, Float),
    lightnesses: Dict(Int, Float),
    hue_ranges: Dict(Int, #(Float, Float)),
  )
}

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
  )
}

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

pub fn to_color(color_hash: ColorHash, input: String) -> Color {
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

  let assert <<hash:32, _:bits>> =
    crypto.hash(crypto.Sha256, bit_array.from_string(input))
  let hue_resolution = 727

  let assert Ok(#(hue_range_start, hue_range_end)) =
    dict.get(hue_ranges, hash % dict.size(hue_ranges))
  let h =
    int.to_float({ hash / dict.size(hue_ranges) } % hue_resolution)
    *. { hue_range_end -. hue_range_start }
    /. int.to_float(hue_resolution)
    +. hue_range_start

  let assert Ok(s) =
    dict.get(saturations, { hash / 360 } % dict.size(saturations))

  let assert Ok(l) =
    dict.get(
      lightnesses,
      { hash / 360 / dict.size(saturations) } % dict.size(saturations),
    )

  let assert Ok(c) = colour.from_hsl(h, s, l)

  c
}
