---
title: Our first pages
description: 
  "Creating the first pages: written in Markdown, converted to HTML, 
  and injected into templates"
synopsis: 
  In this tutorial, we’ll finally dive into the core of the topic by 
  creating our very first pages!
date: 2025-09-05
updates:
  - key: 2025-09-05
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
let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts
let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file
```

</div>

After moving files around, it’s time to start adding real *value* to
our site by **creating our first pages**! This tutorial will introduce
the basics of file reading, document processing, and template
injection.

The main idea in this section is to create pages written in
[Markdown](https://en.wikipedia.org/wiki/Markdown), attach *metadata*
to them, convert them into HTML, and inject them into cascading
templates.


### Additional dependencies

The core of YOCaml can only describe primitive operations on the file
system *in an abstract way*. Usually, it’s the *runtime* (in our case,
`yocaml_unix`) that gives these primitives their **concrete** meaning.
As a result, YOCaml doesn’t know how to handle Markdown, or what it
actually means to insert a document into a template. Fortunately,
there are YOCaml plugins that provide advanced features. For our
purposes, we’ll need two complementary plugins:

- [Yocaml_markdown](https://ocaml.org/p/yocaml_markdown/latest): a
  plugin that converts Markdown documents into HTML. It is built on
  top of the excellent [Cmarkit](https://ocaml.org/p/cmarkit/latest)
  package for document conversion and
  [Hilite](https://ocaml.org/p/hilite/latest) for syntax highlighting
  of code snippets, using TextMate grammars.

- [Yocaml_jingoo](https://ocaml.org/p/yocaml_jingoo/latest): a plugin
  based on [Jingoo](https://ocaml.org/p/jingoo/latest), a template
  engine heavily inspired by
  [Jinja](https://github.com/pallets/jinja/) and offering a wide range
  of features.

- [Yocaml_yaml](https://ocaml.org/p/yocaml_yaml/latest): a plugin that
  allows us to describe metadata using the [YAML](https://yaml.org/)
  language.

We now need to update our `dune-project` file in the `package/blog`
section to add the two packages:


```diff
 (package
  (name blog)
  (synopsis "My first blog using YOCaml")
  (description 
    "My first personal blog using YOCaml for 
    fun and profit")
  (depends
   (ocaml (>= 5.3.0))
 
   (yocaml (>= 2.5.0))
   (yocaml_unix (>= 2.5.0))
+  (yocaml_yaml (>= 2.5.0))
+  (yocaml_markdown (>= 2.5.0))
+  (yocaml_jingoo (>= 2.5.0))
    
   (utop :with-dev-setup)
   (ocamlformat :with-dev-setup)
   (ocp-indent :with-dev-setup)
   (merlin :with-dev-setup)
   (ocaml-lsp-server :with-dev-setup)))
```

In addition, to make them accessible from our blog code (`blog.ml`),
we need to add the dependencies in our `bin/dune` file:


```diff
 (executable 
   (public_name blog)
-  (libraries yocaml yocaml_unix))
+  (libraries yocaml yocaml_unix yocaml_yaml 
+             yocaml_markdown yocaml_jingoo))
```

Now, in our `blog.ml` executable, we will be able to use the
`Yocaml_markdown` and `Yocaml_jingoo` libraries!

### Front Matter and metadata

In most cases, we want to **associate metadata** with a page to provide additional information — for example, the page title, its description, and related tags. YOCaml follows an approach popularized by [Jekyll](https://jekyllrb.com/): the [front matter](https://jekyllrb.com/docs/front-matter/).  

Front matter allows us to attach extra data to a document. It is
written in another language and wrapped between `---` and `---`.


```markdown
---
page_title: Here is the title of my document
description: Here is custom page, as an example
tags: [meta, page, tutorial]
---

# My document markdown

> Hello, welcome to my **custom page**, here is 
> a Markdown document

Hello World!
```

In our example, the front matter is written in YAML. However, you are
free to use alternative formats, such as
[S-expressions](https://en.wikipedia.org/wiki/S-expression),
[ToML](https://ocaml.org/p/yocaml_otoml/latest), or even implement
your own support for a custom description language.


#### Typing metadata

OCaml is a **statically typed** language. Therefore, we want our site
generator to leverage static typing to precisely validate our front
matter according to the types of pages we intend to read.

YOCaml provides a **very rich** API for validating structured data,
ensuring that a document contains sufficient metadata to correctly
build another document.

In this tutorial, we will only use pre-built metadata (informally
called *Archetypes*) to simplify the development of our
project. However, we encourage you to visit the [Data
Validation](/tutorial/validation.html) section for an advanced
tutorial on creating data models.


## Creating our pages

As with previous exercises, we will start by **handling the creation
of a single page**, and then use the `Batch` API to apply our action
to all pages.

First, as always, we will define some variables to make content access
easier.


```ocaml
let content = Path.rel [ "content" ]
let pages = Path.(content / "pages")
```

We can now define an action that will transform Markdown files stored
in `content/pages` into HTML files at the root of our target. In broad
terms, this is how the action will behave:

- It extracts the metadata from the front matter and the content of
  the document.
- It validates the front matter metadata against a schema (and a
  description language, here YAML, via `Yocaml_yaml`).
- It converts the document content from Markdown to HTML using
  `Yocaml_markdown`.
- It injects the metadata and content into a chain of templates (first
  into a layout dedicated to displaying a page, then into the general
  layout of our site, shared among all types of documents).

Without further ado, here is the skeleton of our action:


```ocaml
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline = 
    (* To be completed *)
    assert false 
  in
  Action.Static.write_file page_path pipeline
```

The path definition is a bit more complex than what we did in previous
sections: we compute a path where we move our `source` to the root of
our site (`_www`) and change its extension (from `.md` to `.html`).

We can now **build our pipeline**.


### Reading a file and its metadata

YOCaml provides, once again in the `Pipeline` module, a function that
allows us to read a document and extract its metadata:


```ocaml
# Pipeline.read_file_with_metadata ;;
- : (module Yocaml__.Required.DATA_PROVIDER) ->
    (module Yocaml__.Required.DATA_READABLE with type t = 'a) ->
    ?extraction_strategy:Yocaml.Metadata.extraction_strategy ->
    ?snapshot:bool -> Path.t -> (unit, 'a * string) Task.t
= <fun>
```

The function may seem intimidating, but let's break down its
parameters one by one:

- `(module Required.DATA_PROVIDER)`: the first parameter is a module
  describing the language used for the front matter. In our example,
  we assume our language is YAML, so we can simply use `Yocaml_yaml`
  as the parameter.

- `(module Required.DATA_READABLE)`: the second parameter is also a
  module, which describes how to validate the front matter data. (It's
  important to note that validation is independent of the language
  used; YOCaml uses an intermediate representation that allows a
  `DATA_READABLE` module to work with any `DATA_PROVIDER`). In our
  example, we will use the module
  [Archetype.Page](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Page/index.html),
  which describes a very basic page.

- `?extraction_strategy`: describes how to extract the front
  matter. In our case, there’s no need to change it; we will use the
  default, which encloses the front matter between `---`.

- `?snapshot`: a flag. If set to `true`, the file content will be
  stored in a specific cache to be read only once. By default, this
  flag is `false` (and set to `true` when reading a template). In
  general, there’s no need to worry about it; YOCaml functions choose
  a sensible default.

- `Path.t`: the path to the file we want to read.


```ocaml
# Pipeline.read_file_with_metadata 
    (module Yocaml_yaml)
    (module Archetype.Page)
    (Path.rel ["content"; "pages"; "an_article.md"])
  ;;
- : (unit, Archetype.Page.t * string) Task.t = <abstr>
```

It is worth noting that the `Yocaml_yaml` module provides a function
[`Pipeline.read_file_with_metadata`](https://yocaml.github.io/doc/yocaml_yaml/yocaml_yaml/Yocaml_yaml/Pipeline/index.html#val-read_file_with_metadata),
which makes passing the first module unnecessary.


```ocaml
# Yocaml_yaml.Pipeline.read_file_with_metadata 
    (module Archetype.Page)
    (Path.rel ["content"; "pages"; "an_article.md"])
  ;;
- : (unit, Archetype.Page.t * string) Task.t = <abstr>
```

We can start writing our pipeline like this:


```ocaml
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ _metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content
  in
  Action.Static.write_file page_path pipeline
```

As with creating the CSS file, we *track* the binary first, then
extract the metadata and the content of the file. If we inspect
`_metadata` (we prefixed it with `_` because we are not using it yet),
the variable will have the type `Archetype.Page.t`. If we inspect
`content`, the variable will have the type `string`.


#### Batching our actions

Even though we could delegate this task to the end of our process when
a page is fully built, we think it’s useful to quickly see what’s
happening by running our generator as fast as possible.

Unsurprisingly, batching is trivial to implement. For convenience, we
can even reuse our `with_ext` function to support the different
extensions possible for Markdown:


```ocaml
let create_pages =
  let where = with_ext [ "md"; "markdown"; "mdown" ] in
  Batch.iter_files ~where pages create_page
```

We can now, as usual, modify our main program to execute our
`create_pages` action:

```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_image
   >>= create_css
+  >>= create_pages
   >>= Action.store_cache cache
```

If we run the generator as-is, assuming there is a Markdown page in
`content/pages`, our program should simply copy it to `_www`, removing
the front matter (since we are not doing anything with the metadata).

For example, if we create a file in `content/pages` named
`a_first_article.md` and fill it as follows:


```markdown
# Hello World

> Here is a my **first custom page**!
```

Running `dune exec bin/blog.exe` should correctly copy the file, in
HTML, to the root of our target!

> You might be surprised that the generation works fine even though
> the page has no front matter. This is because the `Page` archetype
> is particularly lenient. It assumes that all required fields are
> optional.


#### The front matter of a page

As we have seen, the page model is very lenient and only requires a
series of optional parameters:

```
page_title: string option
description: string option
tags: list option
display_toc: bool option
```

The `display_toc` field indicates whether to display a table of
contents (but for now, we won’t worry about this field, as it requires
additional work on the pipeline side).

These data can be useful for many purposes, but in our context, we
will use them in our templates. Going forward, you are encouraged to
create several pages, filling in (or not) their front matter.


### Converting Markdown to HTML

Through [Cmarkit](https://ocaml.org/p/cmarkit/latest), the
`Yocaml_markdown` module provides several functions to convert (and
analyze) Markdown documents. For simplicity, we will use the very
straightforward function: `Yocaml_markdown.from_string_to_html`.


```ocaml
# Yocaml_markdown.from_string_to_html ;;
- : ?strict:bool ->
    ?heading_auto_ids:bool ->
    ?highlight:(Cmarkit.Doc.t -> Cmarkit.Doc.t) ->
    ?safe:bool -> string -> string
= <fun>
```

As often with YOCaml, its functions handle many things for the sake of
flexibility. Here, we won’t worry about the optional parameters and
will simply use the function:


```diff
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ _metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
-    content
+    content 
+    |> Yocaml_markdown.from_string_to_html
  in
  Action.Static.write_file page_path pipeline
```

By testing our generator (`dune exec bin/blog.exe`), we can now see
that our page has been successfully converted to HTML — a very good
sign!


## Injecting into templates

Now that we have real HTML pages, it’s time to give them the look of a
proper website.  For this, we will use
[Jingoo](https://ocaml.org/p/jingoo/latest) to define templates where
we can use variables provided, among other things, by the front matter
of our documents.

### Chaining templates

YOCaml does not support *partials* (or *includes*) due to inherent
reasons in its model. To use multiple template files, YOCaml allows
them to be applied successively, which is called a *template cascade*.

In our example, we will have two templates:

- `layout.html`, which defines the general structure of the site and
  will be common to all generated documents (articles and pages).
- `page.html`, which specifically structures a page.

With each application, we add a variable, usable in a template as
`yocaml_body`, representing the *content* of the document being
injected.

### Creating templates

Our templates will go into the `assets/templates` directory and are
regular HTML files. To start, we will create a very simple layout
template. You can download the files
[layout.html](/assets/materials/layout.html) and
[page.html](/assets/materials/page.html) and save them in
`assets/templates`.

To learn more about Jingoo, we recommend visiting the [official
site](https://tategakibunko.github.io/jingoo/) (you can also use the
[playground](https://sagotch.github.io/try-jingoo/)) to explore all
the features provided by the engine. All features are supported in
YOCaml, except for *partials/includes*.


### Using templates

Now that we have our templates, we can use them in our pipelines!
YOCaml offers several approaches for injecting templates, but we will
focus on the simplest one:


```ocaml
# Pipeline.read_templates ;;
- : (module Yocaml__.Required.DATA_TEMPLATE) ->
    ?snapshot:bool ->
    ?strict:bool ->
    Path.t list ->
    (unit,
     (module Yocaml__.Required.DATA_INJECTABLE with type t = 'a) ->
     metadata:'a -> string -> string)
    Task.t
= <fun>
```

Once again, the function may seem **very intimidating**, but we will
see that it is actually quite easy to use!

- `(module Required.DATA_TEMPLATE)` is a module that describes how the
  template engine works. Here, we can simply pass `Yocaml_jingoo` (or
  just use `Yocaml_jingoo.read_template`, which, like `Yocaml_yaml`,
  provides a shortcut).
- `?snapshot` and `strict` are default parameters that we don’t need
  to worry about for now.
- `Path.t list` is the list of templates we want to apply, in order.

  
The subtlety of this task is that it is of type `(unit, _) Task.t`, so
we can perfectly use it with applicative notation, and it returns a
function **that will sequentially apply the templates**. The function
can also seem intimidating:

- `(module Required.DATA_INJECTABLE)` describes how to inject metadata
  into a template. Previously, we used `Archetype.Page` as
  `DATA_READABLE`. It turns out it is also injectable, so we can
  simply use this module.
- `metadata` is the metadata we want to inject, which must have the
  type described by the `DATA_INJECTABLE` module.
- `string` is the content we want to pass from template to template.

We can very easily modify our pipeline to add template support. First,
we will create a `templates` variable, as usual:


```ocaml
let templates = Path.(assets / "templates")
```

Next, we simply retrieve our _application function_:

```diff
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
+   and+ apply_templates = 
+      Yocaml_jingoo.read_templates 
+        Path.[ templates / "page.html"
+             ; templates / "layout.html" ]
    and+ _metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
  in
  Action.Static.write_file page_path pipeline
```

Once that is done, we can simply use the function after converting
Markdown to HTML:


```diff
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ apply_templates = 
       Yocaml_jingoo.read_templates 
         Path.[ templates / "page.html"
              ; templates / "layout.html" ]
-   and+ _metadata, content =
+   and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
+   |> apply_templates (module Archetype.Page) ~metadata
  in
  Action.Static.write_file page_path pipeline
```

<div class="hidden-toplevel">


```ocaml
let create_page source =
  let page_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ apply_templates = 
      Yocaml_jingoo.read_templates 
        Path.[ templates / "page.html"
             ; templates / "layout.html" ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
    |> apply_templates (module Archetype.Page) ~metadata
  in
  Action.Static.write_file page_path pipeline
```

</div>

And there we have it! As we can see, we started our pipeline by
provisioning all the data we need *in parallel*, and then we simply
build the string we want to write to our file!


## Conclusion

We have seen how to create complex tasks and are now able to transform
Markdown pages into HTML pages injected into templates. In short, we
can build a real website!

If you take the time to read the templates we used, you’ll notice that
`yocaml_body` is used extensively — it represents the content of the
file being injected. The *normalization* process (turning a model into
data injectable into the template) of the `Archetype.Page` adds
helpful variables such as `has_page_title`, `has_description`, and so
on.

This was one of the densest parts of this tutorial because it tackled
some of the most challenging concepts!
