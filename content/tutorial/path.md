---
title: Path manipulation
description: An explanation of how paths work
synopsis: 
  In the full guide we used paths fairly implicitly. In this tutorial, 
  it’s time to examine their API more closely to gain greater control.

date: 2025-09-22
updates:
  - key: 2025-09-22
    value:
      description: "First version"
      authors: ["xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
# open Yocaml ;;
```

</div>

Since the purpose of YOCaml is, essentially, **to read files** and
**to write them**, it’s important to have fine-grained control over
file and directory paths! The
[Path](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Path/index.html)
module provides a fairly complete API for working with paths.


## Why use an abstraction

As mentioned in the key concepts, there are several reasons to rely on
an abstraction when working with file paths. In this section, we’ll
briefly cover the two main ones.


### Platform abstraction

YOCaml **abstracts over the platform** it runs on (through its
_runtime_), which allows us to push platform-specific logic to the
outer edges of a program (typically the execution function). While
it’s possible to isolate constants for file path expressions depending
on the platform (for example, `GNU/Linux` vs. `Microsoft Windows`), we
also need to account for structural differences:

- `/home/yocaml/my-folder` is a `Unix-like` path
- `C:\home\yocaml\my-folder` is a `Windows-like` path

In practice, these differences can often be handled using the
[Filename](https://ocaml.org/manual/5.2/api/Filename.html) module
(particularly the
[`dir_sep`](https://ocaml.org/manual/5.2/api/Filename.html#VALdir_sep)
function).  However, relying directly on `Filename` would make path
handling in YOCaml programs less portable, and **there are runtime
contexts very different from those supported by `Filename`**. For
example, in the `Yocaml_git` runtime, file paths are expressed as keys
exposed by
[`Mirage_kv`](https://ocaml.org/p/mirage-kv/latest/doc/mirage-kv/Mirage_kv/index.html).

Using an intermediate representation therefore makes a lot of sense:
we only need to translate the abstract path representation **at the
runtime level**, which lets us target a wide variety of
platforms. Additionally, since the `Path.t` type is abstract, we
retain the freedom to change its internal representation in the future
if we discover a more efficient (or more ergonomic) encoding.

### A convenient API

As we’ve seen, the
[Filename](https://ocaml.org/manual/5.2/api/Filename.html) module is
extremely minimal.  By introducing our own path type, we can provide a
richer API while only requiring the ability to convert our
representation into the one expected by a given _runtime_.

### Path validity

Path descriptions **do not perform any additional validation**, just
like the `Filename` module (for example, whether all characters used
are valid). In practice, this isn’t a real problem, since invalid
paths are quickly caught when used, and we didn’t want to make the API
unnecessarily complicated.

## Creating paths

YOCaml distinguishes between two kinds of paths:

- absolute paths
- relative paths

In practice, when writing a generator, you’ll mostly work with
relative paths to describe locations **from the directory where the
binary is executed**.


```ocaml
# Path.rel [] ;;
- : Path.t = ./
# Path.abs [] ;;
- : Path.t = /
```

The functions `rel` (for *relative*) and `abs` (for *absolute*) both
take a list as their argument.  For example, to describe the relative
path `./foo/bar/baz`, you would write:


```ocaml
# Path.rel ["foo"; "bar"; "baz"] ;;
- : Path.t = ./foo/bar/baz
```

The module also provides a set of [Infix
operators](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Path/index.html#infix-operators)
that make path handling more convenient.

For example, list concatenation:


```ocaml
# Path.(rel ["foo"; "bar"] ++ ["baz"; "index.html"]) ;;
- : Path.t = ./foo/bar/baz/index.html
```

Adding an element to a path (an operator we use often, since it’s
common to define a directory and then specify a single _child_ of that
directory):


```ocaml
# Path.(rel ["foo"; "bar"] / "index.html") ;;
- : Path.t = ./foo/bar/index.html
```

A shortcut for `Path.rel x`. Since we often describe relative paths,
we can use the `~/` operator to define one:


```ocaml
# Path.(~/["foo"; "bar"; "baz"]) ;;
- : Path.t = ./foo/bar/baz
```

## Extensions

In YOCaml, file extensions are often used to indicate how to _process
a file_.  For example, if a file has a `.md` extension, we assume it
should be treated as a Markdown file.  The `Path` module provides
several functions to work with extensions. For illustration, we’ll use
these two paths:


```ocaml
let path_html = Path.(rel ["foo"; "bar"] / "index.html") 
let path = Path.(rel ["foo"; "bar"] / "index") 
```
> From here on, we’ll generally refer to extensions without the `.`.
> However, path-handling functions treat `.ext` and `ext` as equivalent.

Return the extension of a path:

```ocaml
# Path.extension path_html ;;
- : string = ".html"
# Path.extension path ;;
- : string = ""
```

You can see that if the path has no extension, the function returns an
empty string.  There’s also its counterpart, `extension_opt`, which
returns the extension _wrapped_ in an option:


```ocaml
# Path.extension_opt path_html ;;
- : string option = Some ".html"
# Path.extension_opt path ;;
- : string option = None
```

You can also check whether a path has an extension or not:


```ocaml
# Path.has_extension "html" path_html ;;
- : bool = true
# Path.has_extension "md" path ;;
- : bool = false
```

You can also get a path _without its extension_:


```ocaml
# Path.remove_extension path_html ;;
- : Path.t = ./foo/bar/index
```

This has no effect if the path has no extension:


```ocaml
# Path.remove_extension path ;;
- : Path.t = ./foo/bar/index
```

Since it’s possible to get a path without its extension, we can also
return a path with a specific extension:


```ocaml
# Path.add_extension "html" path ;;
- : Path.t = ./foo/bar/index.html
```

**Note**: adding an extension simply _concatenates_ it to the last
fragment of the path.  So if you add the `html` extension to
`path_html`, the extension will be duplicated:


```ocaml
# Path.add_extension "html" path_html ;;
- : Path.t = ./foo/bar/index.html.html
```

You can also combine `remove_extension` and `add_extension` using the
`change_extension` function, which returns a path with its extension
replaced:


```ocaml
# Path.change_extension "md" path_html ;;
- : Path.t = ./foo/bar/index.md
```

In practice, we’ll mostly use `has_extension` to include paths in
_batches_.  Since it’s common to read Markdown files that we want to
convert to HTML, we’ll often use `change_extension` to switch from
Markdown to HTML.


## Resolving paths

Using a path to calculate a new one is **very common** when working
with YOCaml.  For example, imagine that our content is organized like
this:


```ocaml
let content = Path.rel ["content"]
let articles = Path.(content / "articles")
let target = Path.rel ["_www"]
let articles_target = Path.(target / "articles")
```

We could imagine the following article (in Markdown):


```ocaml
# Path.(articles / "my-first-article.md") ;;
- : Path.t = ./content/articles/my-first-article.md
```

And from this article, we might want to calculate the following path:


```ocaml
# Path.(articles_target / "my-first-article.html") ;;
- : Path.t = ./_www/articles/my-first-article.html
```

There are several ways to achieve this result; here, we’ll focus on
the following function:


```ocaml
# Path.move ;;
- : into:Path.t -> Path.t -> Path.t = <fun>
```

The `move` function replaces the `dirname` of a given path. So, we
could imagine a function like this:


```ocaml
let article_path path = 
  path 
  |> Path.move ~into:articles_target
```

```ocaml
# article_path Path.(articles / "my-first-article.md") ;;
- : Path.t = ./_www/articles/my-first-article.md
```

Now, all that’s left is to change the extension:

```ocaml
let article_path path = 
  path 
  |> Path.move ~into:articles_target
  |> Path.change_extension "html"
```

```ocaml
# article_path Path.(articles / "my-first-article.md") ;;
- : Path.t = ./_www/articles/my-first-article.html
```

In practice, these two functions are sufficient for most scenarios
we’d want to handle. Later, we’ll see how to build a _resolver_ to
simplify the calculation of potentially complex paths.


### Preserving Prefixes

In addition to the `move` function, there is also the `relocate`
function:

```ocaml
# Path.relocate ;;
- : into:Path.t -> Path.t -> Path.t = <fun>
```

It is used in exactly the same way, but it offers a subtle difference
compared to `move`: the function tries to preserve common
prefixes. Let’s look at a few examples:

If the two paths are of the same type (`absolute` or `relative`) but
have no common prefixes, the paths are simply concatenated.


```ocaml
# Path.(relocate 
     ~into:(rel ["foo"; "bar"]) 
           (rel ["baz"; "index.html"])) ;;
- : Path.t = ./foo/bar/baz/index.html
```

This differs from `move`, which simply relocates `index.html` (and not
`baz/index.html`):


```ocaml
# Path.(move 
     ~into:(rel ["foo"; "bar"]) 
           (rel ["baz"; "index.html"])) ;;
- : Path.t = ./foo/bar/index.html
```

If the path types are different, the `~into` argument takes precedence
(logically), and the path fragments are concatenated:


```ocaml
# Path.(relocate 
     ~into:(abs ["foo"; "bar"]) 
           (rel ["baz"; "index.html"])) ;;
- : Path.t = /foo/bar/baz/index.html
```

```ocaml
# Path.(relocate 
     ~into:(rel ["foo"; "bar"]) 
           (abs ["baz"; "index.html"])) ;;
- : Path.t = ./foo/bar/baz/index.html
```

If, on the other hand, the path types are the same and the paths share
common prefixes, the target will merge the prefixes:


```ocaml
# Path.(relocate 
     ~into:(rel ["foo"; "bar"]) 
           (rel ["foo"; "bar"; "index.html"])) ;;
- : Path.t = ./foo/bar/index.html
```

In practice, `move` is sufficient. However, when trying to generalize
path calculations — as we’ll see shortly — `relocate` can be
particularly useful.

## Conclusion

We’ve quickly gone over how to manipulate file paths! We’ve seen why
it’s useful to abstract paths — not only to make them
platform-independent, but also to provide useful features (like
extension handling, moving, and relocating).

In the next section, we’ll see **how to create a resolver**, a module
that centralizes path manipulations to handle multiple scenarios.

