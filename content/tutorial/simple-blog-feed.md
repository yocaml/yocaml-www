---
title: Creating a syndication feed
description: Creating an ATOM syndication feed
synopsis: 
   "Now that our blog generator is fully functional (even if the 
   templates and CSS could still be greatly improved), there’s 
   only one thing missing to fully embrace 
   the modern web: a syndication feed!"

date: 2025-09-10
updates:
  - key: 2025-09-10
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
# open Yocaml;;
```

```ocaml
let www = Path.rel [ "_www" ] 
let assets = Path.rel [ "assets" ]
let content = Path.rel [ "content" ]
let templates = Path.(assets / "templates")
let with_ext exts file =
  List.exists (fun ext -> Path.has_extension ext file) exts
let track_binary =
  Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file
let is_markdown = with_ext [ "md"; "markdown"; "mdown" ]
let articles = Path.(content / "articles")
```

```ocaml

let compute_link source =
  let into = Path.abs [ "articles" ] in
  source |> Path.move ~into |> Path.change_extension "html"

let fetch_articles =
  Archetype.Articles.fetch ~where:is_markdown ~compute_link
    (module Yocaml_yaml)
    articles
```

</div>

In this section, we’ll add a final touch to our blog generator: an
[ATOM](https://en.wikipedia.org/wiki/Atom_(web_standard))
feed. Although YOCaml (through _plugins_) can handle [RSS1,
RSS2](https://en.wikipedia.org/wiki/RSS) feeds and even
[OPML](https://en.wikipedia.org/wiki/OPML) feeds, for this tutorial
we’ve chosen to use ATOM — without any particular preference.


## Adding the Plugin

The library for describing syndication feeds is not part of YOCaml’s
core. However, the
[Yocaml_syndication](https://ocaml.org/p/yocaml_syndication/latest)
plugin provides all the primitives needed to build feeds.

First, we’ll update our `dune-project` once again, in the
`package/blog` section, to include the plugin:


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
   (yocaml_yaml (>= 2.5.0))
   (yocaml_markdown (>= 2.5.0))
   (yocaml_jingoo (>= 2.5.0))
+  (yocaml_syndication (>= 2.5.0))
    
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
   (libraries yocaml yocaml_unix))
   (libraries yocaml yocaml_unix yocaml_yaml 
-             yocaml_markdown yocaml_jingoo))
+             yocaml_markdown yocaml_jingoo
+             yocaml_syndication))
```

Do not forget to run `dune build` to regenerate the OPAM file and then
run `opam install . --deps-only` to download the newly added
dependencies.

## Creating the Feed

Creating the feed is fairly straightforward, and the
[Yocaml_syndication.Atom](https://yocaml.github.io/doc/yocaml_syndication/yocaml_syndication/Yocaml_syndication/Atom/index.html)
module is thoroughly documented.

Building a feed revolves around two main functions (which themselves
rely on other helpers). The first one lets us **create an entry in the
feed**:


```ocaml
# Yocaml_syndication.Atom.entry ;;
- : ?authors:Yocaml_syndication.Person.t list ->
    ?contributors:Yocaml_syndication.Person.t list ->
    ?links:Yocaml_syndication.Atom.link list ->
    ?categories:Yocaml_syndication.Category.t list ->
    ?published:Yocaml_syndication.Datetime.t ->
    ?rights:Yocaml_syndication.Atom.text_construct ->
    ?source:Yocaml_syndication.Atom.source ->
    ?summary:Yocaml_syndication.Atom.text_construct ->
    ?content:Yocaml_syndication.Atom.content ->
    title:Yocaml_syndication.Atom.text_construct ->
    id:string ->
    updated:Yocaml_syndication.Datetime.t ->
    unit -> Yocaml_syndication.Atom.entry
= <fun>
```

The second one **builds a feed** from a list of entries:

```ocaml
# Yocaml_syndication.Atom.feed ;;
- : ?encoding:string ->
    ?standalone:bool ->
    ?subtitle:Yocaml_syndication.Atom.text_construct ->
    ?contributors:Yocaml_syndication.Person.t list ->
    ?categories:Yocaml_syndication.Category.t list ->
    ?generator:Yocaml_syndication.Generator.t option ->
    ?icon:string ->
    ?logo:string ->
    ?links:Yocaml_syndication.Atom.link list ->
    ?rights:Yocaml_syndication.Atom.text_construct ->
    updated:Yocaml_syndication.Atom.updated_strategy ->
    title:Yocaml_syndication.Atom.text_construct ->
    authors:Yocaml_syndication.Person.t Nel.t ->
    id:string ->
    ('a -> Yocaml_syndication.Atom.entry) ->
    'a list -> Yocaml_syndication.Xml.t
= <fun>
```

Both functions accept a lot of arguments — however, many of them are
optional. We'll proceed step by step to build the feed.


### Feed Configuration

First, we’ll create a `Feed` module whose purpose is to configure our
ATOM feed. To do this, we can add a `Feed` module in our `blog.ml`
file:


```ocaml
module Feed = struct
  let path = "atom.xml"
  let title = "My first blog using YOCaml"
  let site_url = "https://my_github_name.github.io"
  let feed_description = "My personnal blog using YOCaml"
  
  let owner = 
    Yocaml_syndication.Person.make 
      ~uri:site_url ~email:"me@gmail.com" 
      "John Doe"
      
  let authors = Nel.singleton owner
end
```

The only subtlety in this module is the `owner` variable. The
[`Nel`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Nel/index.html)
module (short for *Non-Empty List*) is used to describe the list of
authors, which cannot be empty. With these variables in place, we’re
ready to move on to the next step.


### Converting an Article

Now that our feed is _configured_, we’ll convert the `path` (the
article’s URL) and `article` pair into an ATOM entry by adding a
function to our module: `article_to_entry`. This function will extract
information from an article and use it to build an ATOM entry.


<!-- $MDX skip -->
```ocaml
let article_to_entry (url, article) =
  let open Yocaml.Archetype in
  let open Yocaml_syndication in
  let page = Article.page article in
  let title = Article.title article
  and content_url = 
    site_url ^ Path.to_string url
    
  and updated = 
    Datetime.make (Article.date article)
    
  and categories = 
    List.map Category.make (Page.tags page)
    
  and summary = 
    Option.map Atom.text (Page.description page) 
  in
  
  let links =
    [ Atom.alternate content_url ~title ] 
  in
  Atom.entry 
    ~links 
    ~categories 
    ?summary 
    ~updated 
    ~id:content_url 
    ~title:(Atom.text title) ()
```

Now that we can convert articles into ATOM entries, it’s time to build
the entire feed.


### Creating the Feed

We can now add a `make` function to the `Feed` module, whose role is
to create a minimalist feed (using relatively few optional
parameters):


<!-- $MDX skip -->
```ocaml
let make entries =
  let open Yocaml_syndication in
  Atom.feed ~title:(Atom.text title)
    ~subtitle:(Atom.text feed_description)
    ~updated:(Atom.updated_from_entries ())
    ~authors ~id:site_url article_to_entry entries
```

This use of `Atom.feed` is very minimal (it will produce a [valid
feed](https://validator.w3.org/feed/check.cgi)), even though it would
be possible to be more precise by addressing some of the _warnings_.


<div class="hidden-toplevel">

```ocaml
module Feed = struct
  let path = "atom.xml"
  let title = "My first blog using YOCaml"
  let site_url = "https://my_github_name.github.io"
  let feed_description = "My personnal blog using YOCaml"

  let owner =
    Yocaml_syndication.Person.make ~uri:site_url ~email:"me@gmail.com"
      "John Doe"

  let authors = Nel.singleton owner

  let article_to_entry (url, article) =
    let open Yocaml.Archetype in
    let open Yocaml_syndication in
    let page = Article.page article in
    let title = Article.title article
    and content_url = site_url ^ Path.to_string url
    and updated = Datetime.make (Article.date article)
    and categories = List.map Category.make (Page.tags page)
    and summary = Option.map Atom.text (Page.description page) in
    let links = [ Atom.alternate content_url ~title ] in
    Atom.entry ~links ~categories ?summary ~updated ~id:content_url
      ~title:(Atom.text title) ()

  let make entries =
    let open Yocaml_syndication in
    Atom.feed ~title:(Atom.text title)
      ~subtitle:(Atom.text feed_description)
      ~updated:(Atom.updated_from_entries ())
      ~authors ~id:site_url article_to_entry entries
end
```

</div>

### Writing the File

Now that we can create a feed and have learned in the previous section
how to retrieve all articles, we can write the feed to our target
source:


```ocaml
let create_feed =
  let feed_path =  Path.(www / Feed.path)
  and pipeline =
    let open Task in
    let+ () = track_binary
    and+ articles = fetch_articles in
    articles 
    |> Feed.make 
    |> Yocaml_syndication.Xml.to_string
  in
  Action.Static.write_file feed_path pipeline
```

We won’t go into this action in detail because it is generally very
similar (and simpler) than the actions we’ve created throughout this
tutorial. It uses the `fetch_articles` function we created earlier. We
can now add `create_feed` to our main program:


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_images
   >>= create_css
   >>= create_pages
   >>= create_articles
   >>= create_index
+  >>= create_feed
   >>= Action.store_cache cache
```

And, as usual, you can test your generator with `dune exec
bin/blog.exe server` and pat yourself on the back for having a fully
functional static site generator!


## Conclusion

Creating a syndication feed simply involves using the functions
provided by the
[`Yocaml_syndication`](https://yocaml.github.io/doc/yocaml_syndication/yocaml_syndication/Yocaml_syndication/index.html)
plugin to create a _feed_, and then converting this _feed_ (which is
an XML document) into a `string`.

To go further, we recommend exploring the module (and potentially [the
specification](https://datatracker.ietf.org/doc/html/rfc4287)) to
include even more data in your _feed_.

