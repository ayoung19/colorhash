import colorhash
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model =
  List(String)

fn init(_) -> Model {
  [""]
}

type Msg {
  OnInput(String)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    OnInput(name) -> [name, ..model]
  }
}

fn view(model: Model) -> Element(Msg) {
  let assert [value, ..] = model

  html.div([attribute.class("container mx-auto p-4")], [
    html.h1([attribute.class("font-mono font-bold text-2xl")], [
      html.text("Color Hash"),
    ]),
    html.p([attribute.class("font-mono text-gray-500 mb-4")], [
      html.text("A Gleam library for deterministic string to color conversion."),
    ]),
    html.input([
      attribute.class(
        "w-full font-mono border-b border-gray-400 outline-none mb-4",
      ),
      attribute.value(value),
      event.on_input(OnInput),
    ]),
    html.div(
      [attribute.class("flex flex-col gap-4")],
      model
        |> list.filter(fn(x) { !string.is_empty(x) })
        |> list.map(fn(x) {
          html.div([attribute.class("flex items-center gap-4")], [
            html.div(
              [
                attribute.class("w-8 h-8"),
                attribute.style(
                  "background-color",
                  colorhash.new() |> colorhash.to_hex(x),
                ),
              ],
              [],
            ),
            html.span([attribute.class("font-mono")], [
              html.text(colorhash.new() |> colorhash.to_hex(x)),
            ]),
            html.span([attribute.class("font-mono underline")], [html.text(x)]),
          ])
        }),
    ),
  ])
}
