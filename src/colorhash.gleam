import gleam/bit_array
import gleam/crypto
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list

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
    hue_ranges: [#(0.0, 359.0)]
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

pub fn to_hsl(color_hash: ColorHash, input: String) -> #(Float, Float, Float) {
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

  #(h, s, l)
}

pub fn to_rgb(color_hash: ColorHash, input: String) -> #(Int, Int, Int) {
  let #(h, s, l) = to_hsl(color_hash, input)
  hsl_to_rgb(h, s, l)
}

pub fn to_hex(color_hash: ColorHash, input: String) -> String {
  let #(r, g, b) = to_rgb(color_hash, input)
  "#" <> int.to_base16(r) <> int.to_base16(g) <> int.to_base16(b)
}

fn hsl_to_rgb(h: Float, s: Float, l: Float) -> #(Int, Int, Int) {
  let c = { 1.0 -. float.absolute_value(2.0 *. l -. 1.0) } *. s
  let h_prime = h /. 60.0
  let h_mod_2 = h_prime -. float.floor(h_prime /. 2.0) *. 2.0
  let x = c *. { 1.0 -. float.absolute_value(h_mod_2 -. 1.0) }
  let m = l -. c /. 2.0

  let #(r1, g1, b1) = case h {
    h if h <. 60.0 -> #(c, x, 0.0)
    h if h <. 120.0 -> #(x, c, 0.0)
    h if h <. 180.0 -> #(0.0, c, x)
    h if h <. 240.0 -> #(0.0, x, c)
    h if h <. 300.0 -> #(x, 0.0, c)
    _ -> #(c, 0.0, x)
  }

  #(
    float.round({ r1 +. m } *. 255.0),
    float.round({ g1 +. m } *. 255.0),
    float.round({ b1 +. m } *. 255.0),
  )
}
