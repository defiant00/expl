# expl

Experimental lazy, functional, data flow programming language.

Implemented in [Zig](https://ziglang.org/), last compiled with 0.11.0-dev.2868+1a455b2dd.

## Layer 0

Simplest overall version focused on validating core ideas without worrying about actual syntax.

* S-expressions
* Lazy
* Algebraic type system
* Multiple inputs and outputs
* Multiple returns
* Partial evaluation
* Order-independent evaluation
* Everything is an expression
* Some sort of explicit ordering of impure functions
* Not OO, but explore code reuse options

### Notes

* Should ast.Node have pointers or direct slices and lists?
* Need to free any AST allocations

```
; a comment
; tokens are split on whitespace and may contain any character except '(' ')' ';'

; function call
(fn-name arg0 arg1 ...)

; 'let' binds a name to a value
(let name value)

; 'fn' defines a function, which can have any number of named and typed inputs and outputs
(fn (list of inputs) (list of outputs) (list of expressions))
```

## Notes

* Data flow programming, defining data transformation steps instead of specific programming instructions.
* Everything's immutable except for specific input/output blocks with some sort of synchronization method.
  * Possibly some sort of step/phase indicator, where any impure commands have to wait for all impure commands from the previous step to finish. This is not necessary if steps are directly dependent on each other, only if indirectly (eg, IO on a variable)
    * `sync` block that takes a value (eg, the result of a variable store, so it must be complete) and the code to then run? may complicate later editing since if new updates are added in the middle then any syncs would also have to be updated
    * simple `step` or `sync` command that guarantees all prior impure functions are done - can be graphical bars like a kanban board separating the sections when edited visually
* All lazily evaluated.
* Types
  * Arbitrarily-sized ints that gracefully degrade to a big int.
  * Real numbers that are stored as a numerator and denominator int.
  * Floats for performance in places that reals don't work.
  * Lists
  * Strings - maybe just a list of characters?
  * Maps
  * Sets
* Blocks can have any number of strongly typed inputs and outputs.
* Equally usable as text or graphical node setup.
  * Comment or special syntax to store visual node metadata as text, so existing text tools are fully supported.
* Basic syntax is `label` `:` `expression`
* Split (only?) on whitespace, so identifiers can be `first-name` or `best!`. Will have to thoroughly investigate how this interacts with other symbols.
* Recommend tabs for indentation so users can customize how they want.

```
# function to repeat each line in a file twice

#! 0, 0 - possible node metadata location syntax
repeat_file_lines: fn(file str) -> void
  content: std.load_file(file)
  lines: content.split('\n')
  duped: lines.each(line => line + '\n' + line)
  joined: duped.join('\n')
  std.save_file(file, joined)
/fn

# simpler in the case of single return values
repeat_file_lines: fn(file str) -> void
  res: std.load_file(file).split('\n').each(line => line + '\n' + line).join('\n')
  std.save_file(file, res)
/fn

# if all steps are pure, only the return values that are actually used are calculated,
# so part or all of this function may not run
some_data: fn() -> (first str, second int)
  # do some calculations
  return.first 'yay'
  # other calculations
  return.second 12
/fn

fn(params as name type) -> void, single type, or multiple values as (name type)
eg:
fn(x int, y int) -> void
fn(x int) -> int
fn(name str) -> (success bool, index int)
```

Possible fn syntax options:
```
no-return: (val str) -> void

one-return: fn(first str, second int) -> int

multi: fn(first str, second int) -> (res1 str, res2 int)
multi: (first str, second int) -> (res1 str, res2 int)
multi: first str, second int -> res1 str, res2 int
multi: (first: str, second: int): (res1: str, res2: int) = body
multi: (first str, second int) (res1 str, res2 int) = body

add: (x: int, y: int): int = x + y
add: (x int, y int) int = x + y

# inline
fn(x int, y int) => return x * y /fn
(x int, y int) => x * y
x int, y int => x * y
```

```
fn range Inf -> [Int]
    return rangeHelper 0
fn range end:Int -> [Int]
    return rangeHelper 0 end
fn range start:Int Inf -> [Int]
    return rangeHelper start
fn range start:Int end:Int -> [Int]
    return rangeHelper start end

fn rangeHelper cur:Int end:Int -> [Int]
    if cur < end
        return cur
        return rangeHelper cur + 1

fn rangeHelper cur:Int -> [Int]
    return cur
    return rangeHelper cur + 1
```
