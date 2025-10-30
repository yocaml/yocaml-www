---
title: Generating CSS
description: "A New Action: Generating CSS file"
synopsis: 
  Having learned how to create actions by copying images, 
  we'll now generate a CSS file from a list of source files.
date: 2025-09-03
updates:
  - key: 2025-09-03
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
```

```ocaml
open Yocaml
let www = Path.rel [ "_www" ] ;;
let assets = Path.rel [ "assets" ]
```

</div>

In this section, we will focus on creating a CSS file. In fact, our
CSS file can be seen as the combination of several different
files. For example, one file to [reset CSS
properties](https://meyerweb.com/eric/tools/css/reset/), another to
import the *fonts*, and a `style.css` file describing the style of our
pages.

We could use the same approach as with
[images](/tutorial/simple-blog-images.html): simply copy all our CSS
files into the target. However, this would mean loading all the CSS
files, in the correct order, within the templates. To avoid this, we
will build an action whose role is to concatenate our CSS files into a
single file before writing it to the target.


### Preparing the files

We’ll start by downloading the files
[reset.css](/assets/materials/reset.css) (the [Modern
Reset](https://www.joshwcomeau.com/css/custom-css-reset/) by [Josh
Comeau](https://www.joshwcomeau.com)) and
[style.css](/assets/materials/style.css) into the `assets/css`
directory.

> As mentioned in the introduction, you are of course free to
> implement your own CSS. That said, we still recommend working with
> multiple files so you can make the most of this guide!


## Merging our stylesheets

The
[Pipeline](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Pipeline/index.html)
module provides a set of functions that generate tasks to help us
build a site. In practice, we often rely on the `Pipeline` module to
retrieve tasks and compose them together. Here, we’ll focus
specifically on the `pipe_files` function:

```ocaml
# Pipeline.pipe_files ;;
- : ?separator:string -> Path.t list -> (unit, string) Task.t = <fun>
```

The function takes an *optional separator* and a **list of files**,
and sequentially joins the contents of the files, separated by the
specified separator.


### Creating a file

In the key concepts, we saw [how to create a
file](/tutorial/key-concepts.html#creating-a-file),
which is probably the most important action in YOCaml. Indeed, a
static site generator can be seen as a *build system* capable of
manipulating the file system, with a particular penchant for writing
things to disk.

YOCaml provides *several actions* for creating files. In this section,
we’ll focus on two essential ones.

#### Creating a static file

We know that YOCaml supports two types of dependencies: **static
dependencies** and **dynamic dependencies**. When we want to create a
file that is not associated with any dynamic dependency, we can use
the `Action.Static.write_file` action, which takes a target as an
argument and a task from `unit` to `string` (the content of our file).


```ocaml
# Action.Static.write_file ;;
- : Path.t -> (unit, string) Task.t -> Action.t = <fun>
```

Under the hood, this is actually the action used by the `copy_file`
action we used earlier. We could imagine rewriting the `copy_file`
action using
[`Pipeline.read_file`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Pipeline/index.html#val-read_file)
like this:


```ocaml
let my_copy_file ~into file = 
  let target = Path.move ~into file in
  Action.Static.write_file target 
     (Pipeline.read_file file)
```


#### Creating a dynamic file

Sometimes, certain tasks produce dynamic dependencies. In this case,
the task must track all dependencies calculated during execution
(these dependencies are stored in the cache). For now, we won’t worry
about dynamic dependencies, as we will cover them in specific guides.


```ocaml
# Action.Dynamic.write_file ;;
- : Path.t -> (unit, string * Deps.t) Task.t -> Action.t = <fun>
```

The key point to remember is that the only difference from static
writing is that our task, in addition to returning the content of the
file to be written, also returns a set of dynamic dependencies that
will be stored in the cache.


### Creating our `style.css`

Now that we know how to write a file and that the pipeline for
*piping* files produces a task of type `(unit, string) Task.t`, which
is compatible with what `Action.Static.write_file` expects, we can
implement our action. First, we’ll declare a variable to target our
`assets/css` directory:


```ocaml
let css = Path.(assets / "css")
```

Next, to implement the `create_css` action, we can rely on the actions
and pipelines we’ve explored earlier:


```ocaml
let create_css =
  let css_path = Path.(www / "style.css") in
  Action.Static.write_file css_path
    (Pipeline.pipe_files ~separator:"\n"
       Path.[ 
          css / "reset.css"
        ; css / "style.css" ])
```

We can now modify our main program by simply adding our new action,
`create_css`, into the sequence of calls:


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_images
+  >>= create_css
   >>= Action.store_cache cache
```

We can run our program with `dune exec bin/blog.exe` and proudly see
our new `_www/style.css` file. Amazing! We can also, once again,
verify that minimal rebuilding is handled correctly by modifying our
source CSS files.

## Tracking the generator

We have seen that our action seems to correctly support minimal
rebuilding. However, **there is still a problem**. If we add a new
file to the list that we *pipe*:

```diff
 let create_css =
   let css_path = Path.(www / "style.css") in
   Action.Static.write_file css_path
     (Pipeline.pipe_files ~separator:"\n"
        Path.[ 
           css / "reset.css"
+        ; css / "a-new-file.css"
         ; css / "style.css" ])
```

When we run `dune exec bin/blog.exe` again (and the file
`assets/css/a-new-file.css` exists), the `_www/style.css` file is
correctly updated. This is expected, as the dependencies of the task
used in `create_css` do include `assets/css/a-new-file.css`.

However, if we change the order of the *pipe*, for example like this:


```diff
 let create_css =
   let css_path = Path.(www / "style.css") in
   Action.Static.write_file css_path
     (Pipeline.pipe_files ~separator:"\n"
        Path.[ 
-          css / "reset.css"
-        ; css / "a-new-file.css"
+          css / "a-new-file.css"
+        ; css / "reset.css"
         ; css / "style.css" ])
```

The reason is *logical*, though somewhat surprising: changing the
order does not alter the set of dependencies. In fact, our use of
`pipe_files` introduces an implicit dependency: **the site generator
itself**, since it is the generator code (here `blog.ml`) that
determines the order of the files. This is therefore also a
dependency.

There are several ways to handle this kind of situation. The first
would be to use a file that exposes the list of files and the order in
which we want to *pipe* them. This is generally good practice because
it relies as much as possible on the file system, which YOCaml handles
fairly well, and it avoids the need to recompile the generator when
introducing new files.

However, since we are just starting with YOCaml, we will use a much
simpler approach: **compose the `pipe_files` task with a task that
simply adds a file to the set of dependencies**:


```ocaml
# Pipeline.track_file ;;
- : Path.t -> (unit, unit) Task.t = <fun>
```

To start, we’ll create a path for the generator binary. In OCaml, the
function
[`Sys.executable_name`](https://ocaml.org/manual/5.3/api/Sys.html#VALexecutable_name)
returns the name of the currently running executable. We can use this
to construct a path and build a task that transparently adds it to the
set of dependencies:


```ocaml
let track_binary = 
  Sys.executable_name
  |> Yocaml.Path.from_string
  |> Pipeline.track_file
```

We now need to use this new task within the body of our file creation
by composing tasks. There are two approaches:


#### Using applicative notation

Applicative notation allows us to use binding operators to express,
schematically, "*add the binary to the dependencies* and *pipe these
different files together*, then *return the piped string*":


```ocaml
let create_css =
  let css_path = Path.(www / "style.css") in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ content =
      Pipeline.pipe_files ~separator:"\n"
        Path.[ 
          css / "reset.css"
        ; css / "style.css" ]
    in
    content
  in
  Action.Static.write_file css_path pipeline
```

In cases like this, where each task can be resolved independently:

- *track* modifications of the binary
- *pipe* the different files

applicative notation is more than sufficient.


#### Using Arrow notation

Our `pipeline` variable uses applicative notation, which we find
easier to read. However, it would also be possible to use Arrow
notation, which is more compact. Indeed, since `track_binary` has the
type `(unit, unit) Task.t`, it can easily be piped with `pipe_file`,
which returns a `(unit, string) Task.t`. We can therefore use the
`>>>` operator:


```ocaml
let create_css =
  let css_path = Path.(www / "style.css") in
  Action.Static.write_file css_path
    Task.(
      track_binary
      >>> Pipeline.pipe_files ~separator:"\n"
            Path.[ 
              css / "reset.css"
            ; css / "style.css" ])
```

In practice, the two notations are **identical in this
context**. However, in this tutorial, we will only use Arrows when
applicative notation is too limited, because in our view, Arrows
require a bit of mental gymnastics due to the use of *tacit style*.


#### Note on the cache

Adding the generator to the dependencies might seem heavy. Indeed, one
might assume that when writing a site, the generator changes
frequently, potentially causing many unnecessary rewrites. In
practice, this is not entirely true for two reasons:

- Even though the generator may change a lot during development, in
  practice, once it is built and we start writing articles, the
  generator changes much less.

- As we discussed with the cache for controlling dynamic dependencies,
  it also stores *hashes* of the written documents to avoid rewriting
  files that haven't been modified. This greatly limits false
  positives when only fragments that do not impact the actual site
  generation are changed.


## Conclusion

We have seen how to **create new files** and how to build more complex
tasks to pass to actions. We have also seen that sometimes there are
dependencies we might not have specifically considered, such as the
binary that runs the program.
