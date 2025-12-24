---
title: Article creation
description: Creation of pages dedicated to articles
synopsis: 
  We have many ingredients to create a real website, now it's time to 
  generate the pages specific to our articles. _Yes_, 
  it's a blog we want to create!
date: 2025-09-08
updates:
  - key: 2025-09-08
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
# #install_printer Yocaml.Data.pp ;;
```

```ocaml
open Yocaml
let www = Path.rel [ "_www" ]
let assets = Path.rel [ "assets" ]
let content = Path.rel [ "content" ]
let templates = Path.(assets / "templates")
let pages = Path.(content / "pages")
let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts
let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file
let is_markdown = with_ext [ "md"; "markdown"; "mdown" ]
```

</div>

We can convert Markdown pages into HTML and inject them into the
template cascade. **Now, it’s time to generate the pages for our
articles!** This section won’t be very different from the previous one,
since we’ll follow the same overall approach. The only things that
will change, _for now_, are the archetype we’ll use and the templates
we’ll chain together.


### The Article Archetype

The
[Article](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Article/index.html)
archetype _inherits_ from the
[Page](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Page/index.html)
archetype. This means that all the fields available in a page can also
be defined in an article! However, if certain optional page fields are
left empty, they will be overridden by specific article fields. Let’s
take a look at the fields provided by `Article`, **in addition to
those from Page**:

- `title`, required `string`, the title of the article (override
  `page_title` if `page_title` is absent)
- `synopsis`, optional `string`, a short description of the article
  (override `description` if `description` is absent)
- `date` required `date`

Inheriting from the `Page` archetype lets us keep using our
`layout.html` template without any worries!


#### About the date field

The date field is quite flexible when it comes to describing a
date. You can also attach a publication time to it. Here are a few
examples of valid dates:


- `2025/08/03`
- `2025/08/03 10:32:16`

And these dates are normalized (injected into a template) in a highly
detailed way, allowing you to strongly customize how a date is
displayed within the template:

```ocaml
# (Data.string "2025/08/03") 
  |> Datetime.validate
  |> Result.map Datetime.normalize
- : (Data.t, Data.Validation.value_error) result =
Ok
 {"year": 2025, "month": 8, "day": 3, "hour": 0, "min": 0, "sec": 0,
 "has_time": false, "day_of_week": 6, "repr":
  {"month": "aug", "datetime": "2025-08-03 00:00:00", "date": "2025-08-03",
  "time": "00:00:00", "day_of_week": "sun"}}
```

Or even:

```ocaml
# (Data.string "2025/08/03 12:34:58") 
  |> Datetime.validate
  |> Result.map Datetime.normalize
- : (Data.t, Data.Validation.value_error) result =
Ok
 {"year": 2025, "month": 8, "day": 3, "hour": 12, "min": 34, "sec": 58,
 "has_time": true, "day_of_week": 6, "repr":
  {"month": "aug", "datetime": "2025-08-03 12:34:58", "date": "2025-08-03",
  "time": "12:34:58", "day_of_week": "sun"}}
```

As you can see, the metadata injected into our template is very rich
and gives you a great deal of freedom on the template side to format
dates exactly as you want!


### A Template for Articles

Just like we did for pages, we’ll create a dedicated template and
inject it into the global layout template. You can download
[article.html](/assets/materials/article.html) and save it in
`/assets/templates`. This template isn’t very different from the one
used for pages, except that it makes use of the `{{ date.repr.datetime
}}` field (and `{{ title }}` as a header).



## Creating Articles

We won’t go into much detail about the article creation action, since
it’s almost the same as for pages. We start by creating a shortcut to
reference the path of the directory where the articles are stored:

```ocaml
let articles = Path.(content / "articles")
```

Next, we create the action for **a single article** (_as usual_),
which is broadly similar to `create_page`, except that we’ll use the
`Article` archetype and inject the `article.html` template instead of
`page.html`:


```ocaml
let create_article source =
  let article_path =
    source
    |> Path.(move ~into:(www / "articles"))
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ templates =
      Yocaml_jingoo.read_templates
        Path.[ templates / "article.html"
             ; templates / "layout.html" ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Article)
        source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
    |> templates (module Archetype.Article) ~metadata
  in
  Action.Static.write_file article_path pipeline
```

We can then create the `create_articles` action, which also works
exactly like `create_pages`:


```ocaml
let create_articles =
  let where = with_ext [ "md"; "markdown"; "mdown" ] in
  Batch.iter_files ~where articles create_article
```

Now we can simply, once again as usual, chain our action into the main
program:


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_images
   >>= create_css
   >>= create_pages
+  >>= create_articles
   >>= Action.store_cache cache
```

And there you have it! We can now create our first article in
`content/articles`:


```markdown
---
title: My first Article
description: Here is my first article
date: 2025-09-08
---

Hello **World**! This is my first article
```

Then test our generator with: `dune exec bin/blog.exe server`. And
there you go! We now support article creation! As you can see, the
code changes very little from what we had for pages.


### A Bit of Refactoring

The processing of pages and articles is so similar that we can easily
_refactor_! The first simple change is to extract the check for
whether a file has a Markdown extension or not:


```diff
+ let is_markdown = with_ext [ "md"; "markdown"; "mdown" ]

 let create_pages =
-  let where = with_ext [ "md"; "markdown"; "mdown" ] in
+  let where = is_markdown
   Batch.iter_files ~where pages create_page

 let create_articles =
-  let where = with_ext [ "md"; "markdown"; "mdown" ] in
+  let where = is_markdown
   Batch.iter_files ~where articles create_article
```

Next, we could consider _sharing_ the action that actually creates the
page and article files. There are several ways to do this, but let’s
go for the simplest approach. First, we’ll start by defining a type
that specifies the kind of document:


```ocaml
type document_kind = 
  | Page 
  | Article
```

Next, we’ll create a function that provides the target based on a path
and a `document_kind`:


```ocaml
let document_path document_kind path =
  let into = match document_kind with 
    | Page -> www 
    | Article -> Path.(www / "articles")
  in
  path |> Path.move ~into |> Path.change_extension "html"
```

We can imagine a function that returns the path to the specific
template:


```ocaml
let get_specific_template document_kind =
  let file = match document_kind with 
    | Page -> "page.html" 
    | Article -> "article.html"
  in
  Path.(templates / file)
```

We can add a function that returns the directories where the sources
are located:


```ocaml
let document_sources = function 
  | Page -> pages 
  | Article -> articles
```

Since our action depends on modules (our _archetypes_), we add a
function that, given a `document_kind`, returns the corresponding
module. We also need to add a signature that specifies that a module
is _both readable and injectable_:


```ocaml
module type ARCHETYPE = sig
  include Yocaml.Required.DATA_INJECTABLE
  include Yocaml.Required.DATA_READABLE with type t := t
end

let document_archetype : document_kind -> (module ARCHETYPE) = 
  function
  | Page -> (module Archetype.Page)
  | Article -> (module Archetype.Article)
```

And now that we have all the ingredients, we can write a generic
action, parameterized by a value of type `document_kind`:


```ocaml
let create_document document_kind source =
  let module Archetype = 
    (val document_archetype document_kind) 
  in
  let target = document_path document_kind source
  and pipeline =
    let open Task in
    let+ () = track_binary
    and+ templates =
      Yocaml_jingoo.read_templates
        Path.[ get_specific_template document_kind
             ; templates / "layout.html" ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata 
         (module Archetype) 
         source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
    |> templates (module Archetype) ~metadata
  in
  Action.Static.write_file target pipeline
```

> If you’re not familiar with _first-class modules_, the OCaml manual
> has [a dedicated
> section](https://ocaml.org/manual/5.3/firstclassmodules.html) that
> thoroughly explains the syntax subtleties used here.


Now we can generalize the iteration over our documents and rewrite our
`create_pages` and `create_articles` functions:


```ocaml
let create_document document_kind =
  let where = is_markdown in
  let sources = document_sources document_kind in
  Batch.iter_files ~where sources 
     (create_document document_kind)
  
let create_pages = create_document Page
let create_articles = create_document Article
```

The goal of this refactoring was to emphasize (once again) that
creating a site generator with YOCaml involves writing a _normal_
OCaml program, and that you can apply your usual refactoring
techniques. Of course, other approaches are also possible.


## Conclusion

This section is complete, and we are very close to having a real blog!
As we’ve seen, creating pages for our articles is, in broad terms, the
same as creating pages; the only significant changes are in the
templates (and the choice of their model/archetype).

