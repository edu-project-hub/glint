package gmark

import "core:fmt"
import "core:log"
import "core:mem"
import "core:reflect"
import "core:slice"
import "core:testing"

// We put all of the lexing directly in the parser, gmark is increadibly hard to lex
Parser :: struct {
	lexer:          Lexer,
	cur_token:      Token,
	peek_token:     Token,
	errors:         int,
	error_callback: Parser_Error_Callback,
	root_elements:  [dynamic]Element_Index,
	elements:       [dynamic]Element,
}

Parser_Error_Callback :: #type proc(token: Token, fmt: string, args: ..any)

parser_create :: proc(lexer: Lexer, error_callback := parser_default_error_callback) -> Parser {
	p := Parser {
		lexer          = lexer,
		error_callback = error_callback,
	}

	next_token(&p)
	next_token(&p)

	return p
}

parser_default_error_callback :: proc(token: Token, format: string, args: ..any) {
	loc := token.loc
	fmt.eprintf("%s(%d:%d) ", loc.file, loc.line, loc.column)
	fmt.eprintf(format, ..args)
	fmt.eprintf("\n")
}

@(private = "file")
error :: proc(p: ^Parser, token: Token, format: string, args: ..any) -> Element {
	if p.error_callback != nil {
		p.error_callback(token, format, ..args)
	}
	p.errors += 1

	return Error_Element{token_clone(token)}
}

@(private = "file")
next_token :: proc(p: ^Parser) {
	destroy_token(p.cur_token)
	p.cur_token = p.peek_token
	p.peek_token = lexer_next_token(&p.lexer)
}

// NOTE(MEMORY): name is the same string like the one from t.data, so best is to just destroy "t" and not do anything
// with name
Block_Element :: struct {
	t:        Token,
	name:     string,
	children: []Element_Index,
}

// NOTE(MEMORY): content is the same string like the one from t.data, so best is to just destroy "t" and not do anything
// with content
Text_Element :: struct {
	t:       Token,
	content: string,
}

Error_Element :: struct {
	t: Token,
}

Element_Index :: int

Element :: union {
	Block_Element,
	Text_Element,
	Error_Element,
}

delete_element :: proc(e: Element, allocator := context.allocator) {
  context.allocator = allocator
	switch e in e {
	case Text_Element:
		destroy_token(e.t)
	case Block_Element:
		destroy_token(e.t)
    delete(e.children)
	case Error_Element:
		destroy_token(e.t)
	}
}

Document :: struct {
	allocator:     mem.Allocator,
	root_elements: []Element_Index,
	elements:      []Element,
}

parse_document :: proc(p: ^Parser) -> Document {
	allocator := context.allocator
	p.root_elements = make([dynamic]Element_Index)
	defer delete(p.root_elements)
	p.elements = make([dynamic]Element)
	defer delete(p.elements)
	for p.cur_token.type != .EOF {
		append(&p.root_elements, parse_element(p))
		next_token(p)
	}

	return {
		elements = slice.clone(p.elements[:]),
		root_elements = slice.clone(p.root_elements[:]),
		allocator = allocator,
	}
}

@(private = "file")
parse_element :: proc(p: ^Parser) -> Element_Index {
	element := Element{}

	#partial switch p.cur_token.type {
	case .OpenParen:
		element = parse_block(p)
	case .Runes, .Identifier:
		cloned_token := token_clone(p.cur_token)
		element = Text_Element {
			t       = cloned_token,
			content = cloned_token.data.(string),
		}
	case:
		element = error(
			p,
			p.cur_token,
			"unexpected token for element %v (%v)",
			p.cur_token.type,
			p.cur_token,
		)
	}

	append(&p.elements, element)
  return len(p.elements)-1
}

@(private = "file")
parse_block :: proc(p: ^Parser) -> Element {
	if p.cur_token.type != .OpenParen {
		return error(p, p.cur_token, "parse_block was called on a wrong token")
	}
	expect_peek(p, .Identifier) or_return
  
  clone := token_clone(p.cur_token)
	block_element := Block_Element {
		t    = clone,
		name = clone.data.(string),
	}
	elements := make([dynamic]Element_Index)
	defer delete(elements)
	for p.peek_token.type != .CloseParen && p.peek_token.type != .EOF {
		next_token(p)
		append(&elements, parse_element(p))
	}

	expect_peek(p, .CloseParen) or_return

	block_element.children = slice.clone(elements[:])
	return block_element
}

@(private = "file")
expect_peek :: proc(p: ^Parser, expected: Token_Type) -> Element {
	if p.peek_token.type != expected {
		return error(
			p,
			p.peek_token,
			"expected %v but got %v (%v)",
			expected,
			p.peek_token.type,
			p.peek_token,
		)
	}
	next_token(p)
	return nil
}

@(private="file")
element_equal :: proc(first: Element, second: Element) -> bool {
  if first == nil {
    return second == nil
  }

  switch first in first {
  case Text_Element:
    text := second.(Text_Element) or_return
    return first.content == text.content
  case Block_Element:
    block := second.(Block_Element) or_return
    (len(block.children) == len(first.children)) or_return
    for child, i in block.children {
      (child == first.children[i]) or_return
    }
    return block.name == first.name
  case Error_Element:
    return true
  }
  unreachable()
}

delete_document :: proc(document: Document) {
		for elem in document.elements {
			delete_element(elem, document.allocator)
		}
		delete(document.elements, document.allocator)
		delete(document.root_elements, document.allocator)
}

@(private = "file")
parser_test :: proc(t: ^testing.T, input: string, expected: Document) {
	l := lexer_create(input, "index.gm")
	p := parser_create(l)

	document := parse_document(&p)
	defer delete_document(document)

  testing.expect_value(t, p.errors, 0)

	if !testing.expectf(
		t,
		len(document.elements) == len(expected.elements),
		"expected %#v, got %#v",
		expected.elements,
		document.elements,
	) {return}
	if !testing.expectf(
		t,
		len(document.root_elements) == len(expected.root_elements),
		"expected %#v, got %#v",
		expected.root_elements,
		document.root_elements,
	) {return}

	for e, i in document.root_elements {
		testing.expect(t, e == expected.root_elements[i])
	}

	for e, i in document.elements {
		testing.expectf(
			t,
			element_equal(expected.elements[i], e),
			"index: %v\n%#v == %#v",
      i,
			expected.elements[i],
			e,
		)
	}
}

@(test)
test_normal_block :: proc(t: ^testing.T) {
	parser_test(
		t,
		"(hi hello world)",
		Document {
			elements = {
				Text_Element{content = "hello"},
				Text_Element{content = "world"},
				Block_Element{name = "hi", children = {0, 1}},
			},
			root_elements = {2},
		},
	)
}
