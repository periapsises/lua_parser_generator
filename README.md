# lua_parser_generator

An SLR(1) parser generator written in LuaJIT. It reads a grammar definition file (`.gmr`) and emits a self-contained Lua source file containing a lexer, a shift-reduce parser, and a concrete syntax tree (CST) builder — all driven by the generated parse tables.

> [!Note]
> **Requires LuaJIT.** The project uses `ffi` and `bit` extensions that are not available in standard Lua 5.x.

---

## Usage

```
luajit parser_generator.lua [options] <input-file>
```

| Option | Description |
|---|---|
| `-o`, `--output <file>` | Path for the generated Lua file. Defaults to the input filename with a `.lua` extension. |
| `-v`, `--verbose` | Print the full LR state table and action map to stdout after generation. |
| `-h`, `--help` | Print help and exit. |
| `--version` | Print the version number and exit. |

**Example:**

```
luajit parser_generator.lua my_language.gmr -o my_language_parser.lua
```

The generated file is self-contained: `require` it and call `parse( input_string )` to get a CST.

---

## Grammar File Format (`.gmr`)

A grammar file has two sections: **token declarations** (the lexer) followed by **rule declarations** (the parser). Both kinds of declaration end with a semicolon.

### Token declarations

Tokens are declared with an `ALL_CAPS` name, a colon, and a **Lua pattern** string:

```
TOKEN_NAME : "lua pattern";
```

Tokens are tried in **declaration order**: the first pattern that matches at the current position wins.

> [!Warning]
> The pattern is anchored to the current position **automatically**; do not add a leading `^`

```
HELLO : "[hH]ello";
COMMA : ",";
```

#### Skip tokens

Add `-> skip` after the pattern to discard matched text (whitespace, comments, etc.):

```
WHITESPACE : " +"       -> skip;
COMMENT    : "//[^\n]*" -> skip;
```

### Rule declarations

Parser rules use a `lowercase_name`, a colon, a body expression, and a semicolon. The first rule declared is the start rule.

```
rule_name : body expression;
```

#### Alternation `|`

A vertical bar separates alternatives:

```
literal : NUMBER | STRING | BOOLEAN;
```

A rule can be split across multiple declarations with the same name — this is equivalent to `|`:

```
statement : assignment;
statement : if_statement;
statement : return_statement;
```

#### Optional `?`

A trailing `?` makes the preceding symbol or group optional (zero or one occurrence):

```
instruction : IDENTIFIER operand_list?;
```

#### Zero or more `*`

A trailing `*` allows zero or more repetitions:

```
program : statement*;
```

#### One or more `+`

A trailing `+` requires at least one occurrence:

```
digit_sequence : DIGIT+;
```

#### Grouping `( ... )`

Parentheses group sub-expressions so that `?`, `*`, `+`, and `|` can apply to multiple symbols:

```
-- alternation of two multi-symbol sequences
(HELLO | GOODBYE) WORLD

-- one or more comma-separated items
operand (COMMA operand)*
```

---

## Full example

```
-- Tokens
IDENTIFIER : "[%a_][%w_]*";
NUMBER     : "%d+";
PLUS       : "+";
STAR       : "*";
LPAREN     : "%(";
RPAREN     : "%)";
WHITESPACE : " +" -> skip;

-- Rules (first rule is the start rule)
expression : term (PLUS term)*;
term       : factor (STAR factor)*;
factor     : NUMBER | IDENTIFIER | LPAREN expression RPAREN;
```

---

## Generated parser API

The generated file returns a table with two functions:

```lua
local parser = require("my_language_parser")

-- Tokenize input and return a token list
local tokens = parser.lex("hello, world!")

-- Parse input and return the root CST node
local cst = parser.parse("hello, world!")
```

### CST node shapes

**Rule node** — produced by a reduce action:
```lua
{
    type     = "node",
    rule     = "rule_name",   -- the grammar rule that was reduced
    children = { ... },       -- ordered child nodes
}
```

**Token node** — produced by a shift action:
```lua
{
    type      = "token",
    tokenType = "TOKEN_NAME", -- the declared token name
    value     = "...",        -- the matched text
}
```
