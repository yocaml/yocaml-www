---
title: Article indexation
description: Creation of an index
synopsis: 
  We’re not far from having a fully functional site. Now that we 
  can create pages and articles, what we’re missing is one specific page, 
  _our index_. This page will let us display a list of our articles, 
  ordered by publication date!
date: 2025-09-08
updates:
  - key: 2025-09-09
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>"]
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
let articles = Path.(content / "articles")
let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts
let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file
let is_markdown = with_ext [ "md"; "markdown"; "mdown" ]
```

</div>

An index is just a regular page, except that it supports more
metadata. In addition to the properties of a page, it has a `{{
articles }}` field, which contains a list of the `Article` archetype
metadata along with an **extra field**, `url`, representing the
(relative) URL of the article.


## Creating the Index

To start with, we’ll treat the index as a normal page, except that
it’s located at the root of `content`. So we can create an action that
will generate our index:


```ocaml
let create_index =
  let source = Path.(content / "index.md") in
  let index_path =
    source 
    |> Path.move ~into:www 
    |> Path.change_extension "html"
  in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ templates =
      Yocaml_jingoo.read_templates
        Path.
          [ templates / "page.html"
          ; templates / "layout.html"
          ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata
        (module Archetype.Page)
        source
    in
    content 
    |> Yocaml_markdown.from_string_to_html
    |> templates (module Archetype.Page) ~metadata
  in
  Action.Static.write_file index_path pipeline
```

And as always, we can add our action to the main program. This time,
there’s no need to _batch_ it, since we’ll only be generating a single
index:


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_image
   >>= create_css
   >>= create_pages
   >>= create_articles
+  >>= create_index
   >>= Action.store_cache cache
```

So far, nothing is different from what we’ve done before. The more
attentive will notice that our `create_index` action—apart from the
source path, which is fixed—is exactly the same as our old
`create_page` action, before we went through the refactoring.


### Adding a Specific Template

Before we update our action to collect articles, we’ll create a
template whose role is to display the list of articles. You can
download the [index template](/assets/materials/index.html) and save
it in the `assets/templates` directory (_as usual_).

> We recommend taking a look at this template, as it combines
> conditionals (using `{% if %}`) and loops (using `{% for %}`).

Now we can update our pipeline to include this template in the list of
applied templates:


```diff
    and+ templates =
      Yocaml_jingoo.read_templates
        Path.
-         [ templates / "page.html"
+         [ templates / "index.html"
+         ; templates / "page.html"
          ; templates / "layout.html"
          ]
```

Since **our index is also a page**, there’s no reason not to use the
`page.html` template as well. However, we add one more template to the
chain, `index.html`, which will define, in HTML, the list of articles
to display.

> Note that depending on where `yocaml_body` is called, the chaining
> logic of the templates can vary. Here, we want the page content to
> appear first, followed by the article list. So we start by rendering
> `yocaml_body` and then display the list of articles.

We can now test our index with `dune exec bin/blog.exe server` and
visit [localhost](http://localhost:8000). At this point, our `index`
should display that there are no articles—which is expected, since we
haven’t yet retrieved the list of articles in our _pipeline_.


## Modifying the Pipeline

Now that our infrastructure (action, template, etc.) is in place, we
can update our pipeline so that it loads all our articles and orders
them. To make this easier, YOCaml’s built-in archetypes provide a
function that automates the collection of multiple files. Its
signature may look intimidating at first, but by examining each of its
arguments, everything should become clear!


```ocaml
# Archetype.Articles.fetch ;;
- : (module Yocaml__.Required.DATA_PROVIDER) ->
    ?increasing:bool ->
    ?filter:((Path.t * Archetype.Article.t) list ->
             (Path.t * Archetype.Article.t) list) ->
    ?on:Eff.filesystem ->
    where:(Path.t -> bool) ->
    compute_link:(Path.t -> Path.t) ->
    Path.t -> (unit, (Path.t * Archetype.Article.t) list) Task.t
= <fun>
```

- `(module DATA_PROVIDER)`: defines how to deserialize the front
  matter, just like when we were reading pages and articles. Here,
  we’ll use `Yocaml_yaml`.

- `increase`: a simple boolean. By default, articles are ordered by
  publication date (descending, so the oldest appears first). However,
  you can change this by setting it to `true`.

- `filter`: allows you to filter the final result list. This was
  particularly useful when using arrow notation, but with applicative
  notation it’s far less necessary.

- `on`: specifies whether to look for files on the source or on the
  target. In our case, we won’t need to worry about this.

- `where`: as in other functions, is a predicate to pre-filter which
  files to consider.

- `compute_link`: a function used to calculate an article’s (relative)
  URL based on its path.

- `Path.t`: the directory where the articles are stored, here
  represented by our `articles` variable.

The task returns a list of articles along with their URLs, as defined
by the `compute_link` function. At first glance, the function may
still seem a bit intimidating, but in practice it’s relatively easy to
use.


### Calculating an Article’s URL

First, let’s calculate the URL of an article. If you recall from
earlier sections, we moved our articles into the `_www/articles/`
directory and changed their extension from Markdown to HTML. We can
apply a similar approach here, except instead of moving them to
`_www/articles`, we place them under `/articles` (at the root of our
server):


```ocaml
let compute_link source =
  let into = Path.abs [ "articles" ] in
  source 
  |> Path.move ~into 
  |> Path.change_extension "html"
```

And that’s it! For the article `content/articles/an-article.md`, the
calculated target will be `_www/articles/an-article.html` and its URL
will be `/articles/an-article.html`.


### Collecting Articles

Now that we know how to calculate a link, we can finally extend our
pipeline to collect all of our articles:


```diff
+ let fetch_articles = 
+   Archetype.Articles.fetch 
+     ~where:is_markdown 
+     ~compute_link
+     (module Yocaml_yaml)
+     articles

 let create_index =
   let source = Path.(content / "index.md") in
   let index_path =
     source 
     |> Path.move ~into:www 
     |> Path.change_extension "html"
   in
   let pipeline =
     let open Task in
     let+ () = track_binary
     and+ templates =
       Yocaml_jingoo.read_templates
         Path.
           [ templates / "page.html"
           ; templates / "layout.html"
           ]
+    and+ articles = fetch_articles
     and+ metadata, content =
       Yocaml_yaml.Pipeline.read_file_with_metadata
         (module Archetype.Page)
         source
     in
     content 
     |> Yocaml_markdown.from_string_to_html
     |> templates (module Archetype.Page) ~metadata
   in
   Action.Static.write_file index_path pipeline
```

We can reuse our `is_markdown` function to only process Markdown
files. Since the front matter of our articles is written in YAML, we
use the `Yocaml_yaml` module and iterate over the files contained in
the directory specified by the `articles` path.


### The `Articles` Archetype

The archetype described by the module
[Yocaml.Archetype.Articles](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Articles/index.html)
is a page with an `articles` field that contains a list of
[Article](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Article/index.html#type-t)
entries, each associated with a `url` field.

We can now use the `with_article` function, which creates an
`Articles.t` by taking a page (here, `metadata`) and our `articles`
variable:


```ocaml
# Archetype.Articles.with_page ;;
- : articles:(Path.t * Archetype.Article.t) list ->
    page:Archetype.Page.t -> Archetype.Articles.t
= <fun>
```

We can then modify our action to build our archetype:


```diff
 let create_index =
   let source = Path.(content / "index.md") in
   let index_path =
     source 
     |> Path.move ~into:www 
     |> Path.change_extension "html"
   in
   let pipeline =
     let open Task in
     let+ () = track_binary
     and+ templates =
       Yocaml_jingoo.read_templates
         Path.
           [ templates / "page.html"
           ; templates / "layout.html"
           ]
     and+ articles = fetch_articles
     and+ metadata, content =
       Yocaml_yaml.Pipeline.read_file_with_metadata
         (module Archetype.Page)
         source
     in
+    let metadata = 
+        Archetype.Articles.with_page
+           ~page:metadata 
+           ~articles
+    in
     content 
     |> Yocaml_markdown.from_string_to_html
-    |> templates (module Archetype.Page) ~metadata
+    |> templates (module Archetype.Articles) ~metadata
   in
   Action.Static.write_file index_path pipeline
```

And there you have it! If you test the generator with `dune exec
bin/blog.exe server`, the index should display (albeit simply) the
list of our articles, ordered in descending order.

The logic for collecting articles is greatly simplified by the
`Archetype.Articles.fetch` function. Note, however, that there is a
more general version available:


```ocaml
# Pipeline.fetch ;;
- : ?only:[ `Both | `Directories | `Files ] ->
    ?where:(Path.t -> bool) ->
    ?on:Eff.filesystem ->
    (Path.t -> 'a Eff.t) -> Path.t -> (unit, 'a list) Task.t
= <fun>
```

This version allows you to dynamically collect files from an
applicative pipeline.


#### About Dynamic Dependencies

In many ways, building an index is very similar to supporting dynamic
dependencies. However, we didn’t have to worry about that! This is
because `track_file` (and `track_files`), used in the `fetch`
function, treats a directory as dependent by considering its
modification time to be the latest of its children. As a result,
whenever the `content/articles` directory is modified, the task is
rerun.

## Conclusion

We’ve seen how to collect multiple files using the `fetch` function!
We now have a fully functional blog, complete with articles, pages,
and an index. To finish, you can create `Contact` and `About` pages so
that the template works seamlessly!
