# expl

Experimental lazy, functional, data flow programming language.

Implemented in [Zig](https://ziglang.org/), last compiled with 0.11.0-dev.1269+c2d37224c.

* Data flow programming, defining data transformation steps instead of specific programming instructions.
* Everything's immutable except for specific input/output blocks with some sort of synchronization method.
  * Possibly some sort of step/phase indicator, where any impure commands have to wait for all impure commands from the previous step to finish. This is not necessary if steps are directly dependent on each other, only if indirectly (eg, IO on a variable)
    * `sync` block that takes a value (eg, the result of a variable store, so it must be complete) and the code to then run? may complicate later editing since if new updates are added in the middle then any syncs would also have to be updated
    * simple `step` or `sync` command that guarantees all prior impure functions are done - can be graphical bars like a kanban board separating the sections when edited visually
* All lazily evaluated.
* Blocks can have any number of strongly typed inputs and outputs.
* Equally usable as text or graphical node setup.
  * Comment or special syntax to store visual node metadata as text, so existing text tools are fully supported.
* Basic syntax is `label` `:` `data`
* Split (only?) on whitespace, so identifiers can be `first-name` or `best!`. Will have to thoroughly investigate how this interacts with other symbols.

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
/fn

one-return: fn(first str, second int) -> int
/fn

multi: fn(first str, second int) -> (res1 str, res2 int)
/fn
multi: (first str, second int) -> (res1 str, res2 int)
/fn
multi: first str, second int -> res1 str, res2 int
/fn

# inline
fn(x int, y int) => return x * y /fn
(x int, y int) => x * y
x int, y int => x * y
```
