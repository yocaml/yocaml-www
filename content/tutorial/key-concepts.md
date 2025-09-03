---
title: Key concepts
description: Explanation of key points and concepts for building with YOCaml
synopsis:
  Now that our environment is properly set up to begin our first project,
  let’s take a moment to review the key concepts needed to understand how 
  YOCaml works.

date: 2025-09-01
updates:
  - key: 2025-09-02
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
```

</div>

Since YOCaml aims to be as generic as possible, the framework
introduces a set of concepts worth reviewing before getting
started. That said, this section contains a lot of information, so
don’t worry if some ideas feel unclear at first — the hands-on
practice in the next section will help make everything much clearer!

## Runtime and Effects

In the previous section, we introduced the idea of a _runtime_ and
briefly mentioned `yocaml_unix`. When writing a YOCaml program, you
typically define a function of type `unit -> unit Yocaml.Eff.t`. This
function must then be **interpreted** in order to actually do
something. This is because YOCaml **abstracts its primitive
operations** through [user-defined
effects](https://ocaml.org/manual/5.3/effects.html). Such abstraction
allows a YOCaml program to run virtually anywhere (including in a web
browser) and greatly simplifies the writing of unit tests. Runtime
plugins provide the mechanisms to interpret the effects propagated by
YOCaml — which can be thought of as YOCaml’s equivalent of _system
calls_.

YOCaml provides three different _runtimes_:

- [Yocaml_unix](https://ocaml.org/p/yocaml_unix/latest): a very simple
  runtime that works on standard Unix architectures. This is the one
  we’ll mainly use throughout the guide to illustrate the different
  sections.

- [Yocaml_eio](https://ocaml.org/p/yocaml_eio/latest): similar to the
  Unix runtime, but built on top of the **multicore** library
  [Eio](https://ocaml.org/p/eio/latest). Its API and usage are very
  close to that of the Unix runtime.

- [Yocaml_git](https://ocaml.org/p/yocaml_git/latest): the most
  innovative runtime. When combined with a more common runtime (like
  `Eio` or `Unix`), it enables building sites directly inside a Git
  repository. These sites can later be served, for example, via
  [MirageOS](https://mirage.io/) using tools such as
  [Unipi](https://github.com/robur-coop/unipi).

In general, runtimes expose two main functions: `run` and
`server`. The former executes a YOCaml program, while the latter
starts a development server — very convenient during the writing
phase.

Looking back at our previous example (and by inspecting the types):


<!-- $MDX skip -->
```ocaml
let program () = 
  Yocaml.Eff.log ~level:`Info "Hello World, from YOCaml"
  
let () = 
  Yocaml_unix.run program
```

The `program` function has the type `unit -> unit Yocaml.Eff.t`, and
we pass it to `Yocaml_unix.run` to execute it. The `run` function
actually takes additional parameters, but we’ll look at those in
detail when we use it in practice.


### A Monad

The type `'a Yocaml.Eff.t` is a **monad** (a kind of IO monad), which
makes it possible to use the usual monadic operators like `>>=`. The
library also provides [binding
operators](https://ocaml.org/manual/5.3/bindingops.html), allowing
YOCaml programs to be written in the following style:


<!-- $MDX skip -->
```ocaml
let a_program () = 
  let open Yocaml.Eff in 
  let* a = effect_a () in 
  let* b = effect_b_that_use a in 
  let* c = effect_c a b in 
  let+ d = effect_d a b c in 
  d
```

In practice, you don’t need a deep understanding of monads to use
YOCaml, and you can consider them **just an implementation
detail**. However, you can find the full [Eff API in the
documentation](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Eff/index.html).


### File Paths

The concept of a _runtime_ introduces potential indirections. Indeed,
file paths are not represented in the same way on Unix, Windows, or in
a Git repository. To handle this, YOCaml provides a
[Path](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Path/index.html)
module that abstracts the notion of a file path.

In broad terms, the module exposes a `rel` function for **qualifying
relative paths** and an `abs` function for **qualifying absolute
paths**. Both functions take a list of strings as arguments:


```ocaml
# Yocaml.Path.rel ["foo"; "bar"; "index.md"] ;;
- : Yocaml.Path.t = ./foo/bar/index.md
```

```ocaml
# Yocaml.Path.abs ["foo"; "bar"; "absolute.md"] ;;
- : Yocaml.Path.t = /foo/bar/absolute.md
```

> **Note:** For ease of use, neither function performs any specific
> checks. They should be seen purely as tools for describing paths,
> while functions that operate on files handle the necessary
> validations.


Although it is common to primarily use **relative paths**, absolute
paths are sometimes necessary, for instance, to specify the path of
the binary currently running the program.


> In this example, _executed within Dune_, the path is relative, but
> typically, when run from a regular program, the computed path is
> absolute.


```ocaml
# Yocaml.Path.from_string Sys.argv.(0) ;;
- : Yocaml.Path.t = ./mdx_gen.bc.exe
```

The module offers many features for working with file paths, and using
YOCaml highlights several recurring patterns. For example, when
processing lists of files, it is common to compute their destination
based on the observed path. For instance, moving a file to another
directory and changing its extension:


```ocaml
# Yocaml.Path.(rel ["articles"; "an_articles.md"]
  |> move ~into:(rel ["_out"; "articles"])
  |> change_extension "html") 
  ;;
- : Yocaml.Path.t = ./_out/articles/an_articles.html
```

In YOCaml, whenever you need to work with paths, you **always** use
this abstraction, which ensures compatibility across all
_runtimes_. Throughout the practical guide, we will explain each
feature in detail. However, if you want to learn more about paths, we
encourage you to read [the dedicated section](/tutorial/path.html).


## Minimality and Dependencies

Building a static site generator _ad hoc_ could simply involve
providing an expressive API to move files and perform
transformations. However, at the start of this section, we have
already covered several concepts that might make using regular
functions (like the _Eff Monad_) seem drastically more
complicated. The reason YOCaml may initially appear intimidating is
that **it strives to ensure the minimality** of each build phase.

The concept of minimality means re-executing **only the tasks
necessary to build a target**. For example, consider the following
task:


![A set of file that introduce dependencies](/assets/images/minimality-1.svg)

Schematically, let’s say we want to produce the files `out1.html` and
`out2.html`. To do this, we first build a `template` using the files
`layout.tpl` and `article.tpl`, then apply it to `content1.md` and
`content2.md` to generate `out1.md` and `out2.md` respectively. In the
scenario shown in the first figure, the files have already been
created. If we run the task, nothing will be executed.

Now imagine **we modify the file `content1.md`**. This change only
affects the file `out1.md` which means that **only the task producing
`out1.md` will be re-executed**, as illustrated in the following
figure:

![A set of file that introduce dependencies](/assets/images/minimality-2.svg)

The next figure illustrates that if we modify `layout.tpl`, the entire
dependency chain will be affected, **triggering the regeneration of
both `out1.md` and `out2.md`**:

![A set of file that introduce dependencies](/assets/images/minimality-3.svg)

Keeping track of the _tasks to be performed_ relies on two kinds of
dependencies: **static dependencies** and **dynamic
dependencies**. Ensuring minimality is one of the main reasons why
YOCaml’s API is somewhat more complex to use than just _simple regular
functions_.

### Static Dependencies

We refer to dependencies as static when they can be observed
_statically_ (as the name suggests), meaning **there is no need to
execute the task to know that the dependency exists**. For example,
consider a scenario similar to the one illustrated earlier: to produce
the file `out.html`:

- read `content.md`
- convert the contents of `content.md` into HTML
- read the `article.tpl` template
- inject the freshly converted HTML into the template
- read the `layout.tpl` template
- inject the previous content into this template
- write the final content to the file `out.html`

In this scenario, `out.html` is called the **target**, and its
dependencies — **known statically** — are: `content.md`, `article.tpl`,
and `layout.tpl`. The task that produces `out.html` will only be
executed if `out.html` (the target) does not exist or if at least one
of its dependencies has been modified after `out.html`.

Static dependencies are usually the ones you’ll encounter most often
when writing a YOCaml project, and the entire framework is designed to
make handling them easy, with support that is almost transparent to
the user.


### Dynamic Dependencies

In contrast to static dependencies, **dynamic dependencies cannot be
observed statically**. These are dependencies that are computed (_as
the name suggests_) dynamically.

A common example would be when building a file (a _target_), you first
read another file, and that file returns a list of files to be used in
order to generate the final output.


#### Caching System

The presence of dynamic dependencies requires a caching system to
maintain build information from one build to the next. Without this
cache, it would be necessary to **rebuild targets with dynamic
dependencies every time**. The cache acts as a record of the previous
build, allowing tasks to be _skipped_ when appropriate.

## Actions

Since the tasks we want to express can potentially introduce dynamic
dependencies, YOCaml provides a type that represents taking the
`Cache` as an argument and returning it (wrapped in the `Eff`
monad). This type, exposed in the
[Action](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Action/index.html#type-t)
module, is: `Yocaml.Cache.t -> Yocaml.Cache.t Yocaml.Eff.t`.

In practice, a YOCaml project is **a sequence of actions** and looks
like this:


<!-- $MDX skip -->
```ocaml
let program () = 
  let open Yocaml.Eff in 
  let cache_file = Yocaml.Path.rel [".my-cache"] in
  Yocaml.Action.restore_cache cache_file
  >>= action_a 
  >>= action_b 
  >>= action_c
  >>= Yocaml.Action.store_cache cache_file
  
let () = 
  Yocaml_unix.run program
```

An action modifies the cache and passes it to the next one. Actions
can serve different purposes, such as copying files, building pages
from multiple files, and so on.


#### Binding Operators

The introduction of [binding
operators](https://ocaml.org/manual/5.3/bindingops.html) in OCaml made
the use of the older infix operators somewhat obsolete. However, in
cases of chaining actions — where the cache is passed from one action
to the next — we find that using the classic `bind` operator (`>>=`)
is more ergonomic. For example, let’s revisit the previous example
using binding operators:

<!-- $MDX skip -->
```ocaml
let program () =
  let open Yocaml.Eff in 
  let cache_file = Yocaml.Path.rel [".my-cache"] in
  let* cache = Yocaml.Action.restore_cache cache_file in
  let* cache = action_a cache in 
  let* cache = action_b cache in 
  let* cache = action_c cache in 
  Yocaml.Action.store_cache cache_file

let () = 
  Yocaml_unix.run program
```

However, both versions of the code are equivalent, so you are free to
choose the syntax you prefer.


### Creating a File

To understand what actions actually are, let’s look at a function that
allows us to create a file:


```ocaml
# Yocaml.Action.Static.write_file ;;
- : Yocaml.Path.t -> (unit, string) Yocaml.Task.t -> Yocaml.Action.t = <fun>
```

The function takes two arguments: a target (the file to create) and a
task to execute (we’ll look at this in more detail in the next
section), and it returns an `Action` — a function that takes the cache
and returns it wrapped in an effect. The task passed as an argument is
the concrete action to perform, and it is the execution of this task
that may be skipped for reasons of minimality, as discussed in the
previous section.

Here is a simple example of an action that writes a file with a
constant value (and therefore has no dependencies):

```ocaml
# let create_file target = 
    Yocaml.Action.Static.write_file target
      (Yocaml.Task.const "Hello World")
  ;;
val create_file : Yocaml.Path.t -> Yocaml.Action.t = <fun>
```

As mentioned in the introduction, hands-on practice in the full
tutorial will provide much more information and intuition on how to
use the various functions in the YOCaml API.

## Task

We now arrive at the last of the key concepts: tasks, which we have
implicitly referred to throughout this section. Tasks are a kind of
function that maintain a set of static dependencies. Accordingly, the
type `('a, 'b) Yocaml.Task.t` describes a function from `'a` to `'b
Yocaml.Eff.t` along with a set of static dependencies.

For example, let’s use functions from the
[Pipeline](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Pipeline/index.html)
module, which provides a set of prebuilt tasks, such as reading
files. Here, we create a task that takes two file paths as arguments
and constructs a task that _pipes_ them:


```ocaml
# let pipe_two_files a b = 
    let open Yocaml.Task in
    let+ fst_file = Yocaml.Pipeline.read_file a 
    and+ snd_file = Yocaml.Pipeline.read_file b in
    fst_file ^ "\n" ^ snd_file
  ;;
val pipe_two_files : Yocaml.Path.t -> Yocaml.Path.t -> string Yocaml.Task.ct =
  <fun>
```

Notice that we need to use the `let+` and `and+` operators to collect
the static dependencies of the two steps.

We can also inspect the dependencies of our task, which are known
statically, quite easily:

```ocaml
# pipe_two_files 
      (Yocaml.Path.rel ["a.md"])
      (Yocaml.Path.rel ["b.md"])
  |> Yocaml.Task.dependencies_of ;;
- : Yocaml.Deps.t = Deps [./a.md; ./b.md]
```

And we could use our task to create a file in the following way:

```ocaml
# let my_action =
    let target = Yocaml.Path.rel ["out.md"] in
    Yocaml.Action.Static.write_file 
      target
      (pipe_two_files 
         (Yocaml.Path.rel ["a.md"]) 
         (Yocaml.Path.rel ["b.md"]))
  ;;
val my_action : Yocaml.Action.t = <fun>
```

### Parallelism and Sequentiality

The type of our task is `string Yocaml.Task.ct`. In fact, the type
`ct` is an alias defined as `'a Yocaml.Task.ct = (unit, 'a)
Yocaml.Task.t`, which uses the **Applicative** interface of
tasks. This design **allows static dependencies to be collected**,
since each task can be executed independently (this is the difference
between applicative execution and monadic execution, which is
sequential).

However, sometimes we want **to use the result of one task as the
input to another task**. This is especially useful when applying a
sequence of templates in a _cascading_ manner. That’s why a task’s
type is parameterized by both its input and output types.

For these scenarios, we need a construct slightly more powerful than
an applicative: an **Arrow** which provide composition operators that
allow you to statically combine the static part of a task (its
dependencies) while _piping_ the result. Unlike Applicatives, Arrows
do not offer simple syntax with binding operators and require the use
of [infix
operators](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Task/index.html#infix-operators),
which are a bit more cumbersome to use.

For example, to rewrite `pipe_two_files` using Arrows, we could do the
following:


```ocaml
# let pipe_two_files_using_arrow a b = 
    let open Yocaml.Task in
    ((Yocaml.Pipeline.read_file a) 
      &&& (Yocaml.Pipeline.read_file a))
    >>| (fun (fst_file, snd_file) -> 
          fst_file ^ "\n" ^ snd_file)
  ;;
val pipe_two_files_using_arrow :
  Yocaml.Path.t -> 'a -> (unit, string) Yocaml.Task.t = <fun>
```

This function is identical to the previous one but much more
intimidating because it requires programming in a
[_point-free_](https://en.wikipedia.org/wiki/Tacit_programming) style,
which can quickly become frustrating. However, in YOCaml, we usually
use `>>|` to _pipe_ a task with a regular function and `>>>` to _pipe_
two tasks together.


### Combining Applicative Notation and Arrows

To keep our tutorials as simple as possible, we will primarily use
applicative notation and only rely on Arrows when strictly necessary.

For example, here is a case that uses both notations. The applicative
approach is used to build everything that can be resolved without
sequentiality, and at the end, Arrow notation is used to introduce
sequentiality by applying templates (using a function implemented for
the purposes of this example, which does not exist in the YOCaml API
for simplicity):


<div class="hidden-toplevel">

```ocaml
module Dummy_tpl = struct 
  type t = string
  let normalize r = 
    [("result", Yocaml.Data.string r)]
end

let apply_tpl tpl = 
  Yocaml_jingoo.Pipeline.as_template
      (module Dummy_tpl)
      (Yocaml.Path.from_string tpl)
```

</div>

```ocaml
# let article_task source =
    let open Yocaml.Task in
    let prepare =
      let config_file = Yocaml.Path.rel ["config.md"] in
      let+ content = Yocaml.Pipeline.read_file source
      and+ config  = Yocaml.Pipeline.read_file config_file in
      (config, Yocaml_markdown.from_string_to_html content)
    in
    (* Here, we are using arrow API *)
    prepare 
    >>> apply_tpl "article-tpl.html"
    >>> apply_tpl "layout-tpl.html"
   ;; 
val article_task : Yocaml.Path.t -> (unit, string * string) Yocaml.Task.t =
  <fun>
```

The first parameter is used to store the metadata of the article — in
this case, our configuration — and we sequentially apply the
`article.html` and `layout.html` templates (so the content resulting
from applying the `article.html` template to our configuration and
content pair will be passed to the `layout.html` template).

As before, we can inspect the static dependencies of our task:


```ocaml
# Yocaml.Task.dependencies_of 
    (article_task (Yocaml.Path.rel ["an_article.md"])) ;;
- : Yocaml.Deps.t =
Deps [./an_article.md; ./article-tpl.html; ./config.md; ./layout-tpl.html]
```

And we can write an action that writes the file we have
constructed. Here, since we associate the file content with metadata
(from our `config.md`), we use a slightly different function,
`Yocaml.Action.Static.write_file_with_metadata`:

```ocaml
# let article_action source = 
    let open Yocaml.Path in
    let target = 
      source
      |> move ~into:(rel ["_target_"]) 
      |> change_extension "html"
    and task = article_task source in
    Yocaml.Action.Static.write_file_with_metadata
       target 
       task

  ;;
val article_action : Yocaml.Path.t -> Yocaml.Action.t = <fun>
```

Since `Yocaml.Action.Static.write_file_with_metadata` is an `Action`,
it returns a function `Cache.t -> Cache.t Eff.t`, so by **partial
application** we obtain a new action. You can find more examples of
task construction and composition in the [dedicated
tutorial](/tutorial/task.html).


## Conclusion

We’ve covered many concepts, but at this point, we have seen enough to
dive into the concrete design of a blog using YOCaml. If some things
still seem unclear, the hands - on tutorial should clarify everything.

_You are ready to get to the heart of the matter_!

