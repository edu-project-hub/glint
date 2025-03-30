package main

import "core:os"
import "core:fmt"
import gmark ".."

main :: proc() {
  data, ok := os.read_entire_file_from_filename("index.gm")
  if !ok {
    fmt.eprintln("index.gm:", ok)
    return
  }
  fmt.printfln("data: %q", data)

  l := gmark.lexer_create(string(data), "index.gm")
  p := gmark.parser_create(l)
  doc := gmark.parse_document(&p)
  defer gmark.delete_document(doc)
  fmt.printfln("%#v", doc)
}
