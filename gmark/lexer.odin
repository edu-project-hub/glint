package gmark

/*
Alot of this code is copied and modified over from https://github.com/odin-lang/Odin/blob/master/core/odin/tokenizer/token.odin
It is distributed under the 3-clause BSD License. Following is the LICENSE:


Copyright (c) 2016-2024 Ginger Bill. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import "core:fmt"
import "core:log"
import "core:strings"
import "core:unicode/utf8"

Token_Type :: enum {
	// Signal Tokens
	Invalid,
	EOF,

	// Literals
	Identifier,
	Runes,

	// Punctuation
	OpenParen,
	CloseParen,
}

Token :: struct {
	type: Token_Type,
	loc:  Loc,
	data: union {
		// Identifier, Characters
		string,
	},
}

Loc :: struct {
	file:   string,
	line:   int,
	column: int,
}

Error_Callback :: #type proc(loc: Loc, fmt: string, args: ..any)

Lexer :: struct {
	// Immutable
	input:            string,
	file:             string,
	error_callback:   Error_Callback,

	// State
	ch:               rune,
	pos:              int,
	peek_pos:         int,
	last_line_pos:    int,
	line:             int,

	// Mutable
	errors:           int,
	insert_semicolon: bool,
}

default_error_callback :: proc(loc: Loc, format: string, args: ..any) {
	fmt.eprintf("%s(%d:%d) ", loc.file, loc.line, loc.column)
	fmt.eprintf(format, ..args)
	fmt.eprintf("\n")
}

init :: proc(
	l: ^Lexer,
	input: string,
	file: string,
	error_callback: Error_Callback = default_error_callback,
) {
	l.input = input
	l.file = file
	l.error_callback = error_callback

	l.ch = ' '
	l.pos = 0
	l.peek_pos = 0
	l.line = len(input) > 0 ? 1 : 0
	l.last_line_pos = 0
	l.errors = 0
	l.insert_semicolon = false

	next_ch(l)
	if l.ch == utf8.RUNE_BOM {
		next_ch(l)
	}
}

@(private)
pos_to_loc :: proc(l: ^Lexer, pos: int) -> Loc {
	return Loc{file = l.file, line = l.line, column = pos - l.last_line_pos + 1}
}

error :: proc(l: ^Lexer, pos: int, format: string, args: ..any) {
	loc := pos_to_loc(l, pos)
	if l.error_callback != nil {
		l.error_callback(loc, format, ..args)
	}
	l.errors += 1
}

next_ch :: proc(l: ^Lexer) {
	if l.peek_pos < len(l.input) {
		l.pos = l.peek_pos
		if l.ch == '\n' {
			l.last_line_pos = l.pos
			l.line += 1
		}
		r, w := rune(l.input[l.peek_pos]), 1
		switch {
		case r == 0:
			error(l, l.pos, "illegal NUL character encountered")
		case r >= utf8.RUNE_SELF:
			r, w = utf8.decode_rune_in_string(l.input[l.peek_pos:])
			if r == utf8.RUNE_ERROR && w == 1 {
				error(l, l.pos, "illegal UTF-8 character")
			} else if r == utf8.RUNE_BOM && l.pos > 0 {
				error(l, l.pos, "illegal byte order mark")
			}
		}
		l.peek_pos += w
		l.ch = r
	} else {
		l.pos = len(l.input)
		if l.ch == '\n' {
			l.last_line_pos = l.pos
			l.line += 1
		}
		l.ch = -1
	}
}

peek_byte :: proc(l: ^Lexer) -> byte {
	if l.peek_pos < len(l.input) {
		return l.input[l.peek_pos]
	}
	return 0
}

is_alpha :: proc(ch: rune) -> bool {
	return ('a' <= ch && ch <= 'z') || ('A' <= ch && ch <= 'Z')
}

is_identifier_ch :: proc(ch: rune) -> bool {
	return is_alpha(ch) || ch == '_' || ('0' <= ch && ch <= '9')
}

is_whitespace :: proc(ch: rune) -> bool {
	return ch == ' ' || ch == '\r' || ch == '\n' || ch == '\t'
}

is_reserved :: proc(ch: rune) -> bool {
  return ch == '(' || ch == ')' || ch == '#'
}

read_identifier :: proc(l: ^Lexer, loc: Loc) -> Token {
	start_pos := l.pos
  b : strings.Builder
  strings.builder_init(&b)

	type := Token_Type.Identifier
	for is_identifier_ch(l.ch) && l.ch != -1 {
    strings.write_rune(&b, l.ch)
		next_ch(l)
	}

	if !is_whitespace(l.ch) && l.ch != -1 && !is_reserved(l.ch) {
    escape := false
		type = .Runes
		for !is_whitespace(l.ch) && l.ch != -1 {
      if !escape && l.ch == ')' {
        break
      }
      if l.ch == '\\' && !escape {
        escape = true
        next_ch(l)
        continue
      }

      if escape {
        escape = false
        switch l.ch {
        case ')', '(', '\\', '#':
          strings.write_rune(&b, l.ch)
          next_ch(l)
          continue
        case:
          error(l, l.pos, "invalid escape character '%r'", l.ch)
        }
      }
      strings.write_rune(&b, l.ch)
			next_ch(l)
		}
	}

	if start_pos == l.pos {
		error(l, l.pos, "Illegal empty identifier")
		return Token{type = .Invalid, loc = loc, data = nil}
	}

	return Token{type = type, loc = loc, data = strings.to_string(b)}
}

skip_whitespace :: proc(l: ^Lexer) {
	for is_whitespace(l.ch) {next_ch(l)}
}

next_token :: proc(l: ^Lexer) -> Token {
	skip_whitespace(l)
	type := Token_Type.Invalid
	loc := pos_to_loc(l, l.pos)

	switch l.ch {
	case -1:
		type = .EOF
	case '(':
		type = .OpenParen
	case ')':
		type = .CloseParen
  case '#':
    if peek_byte(l) == '(' {
      next_ch(l)
      next_ch(l)

      for !(l.ch == ')' && peek_byte(l) == '#') && l.ch != -1 {
        next_ch(l)
      }
      next_ch(l)
      next_ch(l)
    } else {
      for l.ch != '\n' && l.ch != -1 {
        next_ch(l)
      }
    }
    return next_token(l)
	case:
		return read_identifier(l, loc)
	}
	next_ch(l)
	return Token{loc = loc, type = type, data = nil}
}

destroy_token :: proc(token: Token) {
	if str, ok := token.data.(string); ok {
		delete_string(str)
	}
}


// Testing

import "core:testing"

@(private)
test_expect_loc :: proc(t: ^testing.T, t_loc, expected_loc: Loc, additonal_info := "") {
	testing.expectf(
		t,
		t_loc.column == expected_loc.column,
		"Loc column did not match %s",
		additonal_info,
	)
	testing.expectf(
		t,
		t_loc.line == expected_loc.line,
		"Loc line did not match %s",
		additonal_info,
	)
}

@(private)
test_expect_token :: proc(
	t: ^testing.T,
	tok: Token,
	expected_type: Token_Type,
	expected_loc: Loc,
	additonal_info := "",
) {
	testing.expectf(
		t,
		tok.type == expected_type,
		"Expected tok.type %v to be %v %s",
		tok.type,
		expected_type,
		additonal_info,
	)
	test_expect_loc(t, tok.loc, expected_loc, additonal_info)
}

@(private)
test_expect_token_string :: proc(
	t: ^testing.T,
	tok: Token,
	expected_type: Token_Type,
	expected_loc: Loc,
	expected_string: string,
	additonal_info := "",
) {
	test_expect_token(t, tok, expected_type, expected_loc, additonal_info)
	actual_string, ok := tok.data.(string)
	testing.expectf(t, ok, "Expected tok.data to be a string %s", additonal_info)
	testing.expectf(
		t,
		expected_string == actual_string,
		"Expected token data string to be \"%s\", but it is \"%s\"",
		expected_string,
		actual_string,
	)
}

@(private)
test_make_lexer :: proc(t: ^testing.T, input: string) -> (lexer: Lexer, tokens: [dynamic]Token) {
	lexer = Lexer{}
	init(&lexer, input, "init.gm")

	tokens = make([dynamic]Token)

	found_invalids := 0

	for token := next_token(&lexer); token.type != .EOF; token = next_token(&lexer) {
		if token.type == .Invalid {
			found_invalids += 1
		}
		_, err := append(&tokens, token)
		if err != .None {
			log.error("Error while appending token to tokens %v", err)
			testing.fail(t)
		}
	}

	if lexer.errors > 0 {
		log.error("The lexer encountered one or more errors")
	} else if found_invalids > 0 {
		log.error("The lexer returned one or more Invalid tokens without emiting an error")
	}

	return
}

@(private)
test_delete_tokens :: proc(tokens: [dynamic]Token) {
	for token in tokens {
		destroy_token(token)
	}
	delete(tokens)
}

@(private)
test_expect_tokens :: proc(t: ^testing.T, expected_tokens: []Token, actual_tokens: []Token) {

	if !testing.expectf(
		t,
		len(expected_tokens) == len(actual_tokens),
		"expected %#v == %#v",
		expected_tokens,
		actual_tokens,
	) {
		return
	}

	for tok, i in expected_tokens {
    index_error := fmt.aprintf("(index %d e: %v, a: %v)", i, tok, actual_tokens[i])
		defer delete(index_error)

		if s, ok := tok.data.(string); ok {
			test_expect_token_string(t, actual_tokens[i], tok.type, tok.loc, s, index_error)
		} else {
			test_expect_token(t, actual_tokens[i], tok.type, tok.loc, index_error)
		}
	}
}

@(test)
basic_block :: proc(t: ^testing.T) {
	input := "(hi hiä hi)"
	_, tokens := test_make_lexer(t, input)
	defer test_delete_tokens(tokens)


	test_expect_tokens(
		t,
		[]Token {
			{type = .OpenParen, loc = {line = 1, column = 1}},
			{type = .Identifier, loc = {line = 1, column = 2}, data = "hi"},
			{type = .Runes, loc = {line = 1, column = 5}, data = "hiä"},
			{type = .Identifier, loc = {line = 1, column = 10}, data = "hi"},
			{type = .CloseParen, loc = {line = 1, column = 12}},
		},
		tokens[:],
	)
}

@(test)
basic_escape :: proc(t: ^testing.T) {
  input := "\\\\ \\(\\)"
  _, tokens := test_make_lexer(t, input)
  defer test_delete_tokens(tokens)

  test_expect_tokens(t, []Token{
    {type = .Runes, loc = {line = 1, column = 1}, data = "\\"},
    {type = .Runes, loc = {line = 1, column = 4}, data = "()"},
  }, tokens[:])
}

@(test)
correct_comment_handling :: proc(t: ^testing.T) {
  input := `
  # Hello World
  #(hi)#
  hi
  `
  _, tokens := test_make_lexer(t, input)
  defer test_delete_tokens(tokens)
  test_expect_tokens(t, []Token{{type = .Identifier, loc = {line = 4, column = 3}, data = "hi"}}, tokens[:])
}
