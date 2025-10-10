---
title: Path resolver
description: A module for solving paths
synopsis: 
  "Now that we’ve seen how to manipulate paths, let’s look at a 
  technique commonly used by YOCaml developers when writing generators:
  centralizing all path computations in a single module, usually called 
  a _resolver_."

date: 2025-09-23
updates:
  - key: 2025-09-23
    value:
      description: "First version"
      authors: ["xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
# module Path = Yocaml.Path ;;
module Path = Yocaml.Path
```

</div>

This guide is essentially about establishing good practices, but it
won’t teach you anything new that is specific to YOCaml.

## The Three Contexts

Even though in the main guide we treated paths in a fairly uniform
way, when generating a static site there are actually **three
contexts** for our paths:

- **The source**, which lets us _fetch_ the documents (or _assets_)
  we’ll use to create targets.  For example: `./content/articles`,
  describing the source of our articles.

- **The target**, which describes the paths where _we’ll create
  artifacts_.  For example: `./_www/articles`, describing the
  destination where we’ll generate the articles.

- **The server**, which describes the paths relative to the server
  that serves our site.  This is useful for computing article links
  (particularly for the [index](simple-blog-index.html) and the
  [feed](simple-blog-feed.html)).  For example:
  `/articles/my-first-article.html`, the URL (relative to our server)
  of an article.

We could imagine other contexts (like a _cache_, if we wanted to build
more ambitious caching strategies). However, for the purposes of this
guide, we’ll keep things simple.

While it’s possible to handle these paths in an _ad-hoc_ way, as your
generator grows more complex, centralizing path calculations in a
module makes development much simpler. For example, this documentation
site uses a
[_resolver_](https://github.com/yocaml/yocaml-www/blob/main/lib/resolver.mli).

In this guide, we’ll see how to create a _resolver_ that can be passed
from one action to another, making our generator more modular and
helping solve potential issues cleanly.

> **Note**: There’s no single way to write a _resolver_.  In this
> article, we’ll present an approach that’s both easy to adapt to your
> needs and not too intrusive.


### An Annoying Problem

Beyond being a robust way to handle paths, using a _resolver_ also
helps avoid a potentially frustrating issue.  In our earlier examples,
as soon as we invoked the [development
server](simple-blog-server.html), we assumed our site would **always
be served from the root**.  Indeed, even if we pass a _target_
directory to the server (so it knows which folder to serve
statically), the server itself will always start from `/`.

In practice, this isn’t always true. A common case is when deploying
to _GitHub Pages_, where the site root might actually be
`/project-name/`.

By implementing a _resolver_ strategically, we can handle this issue
in an almost completely transparent way.


## Resolver for the Simple Blog Tutorial

Building on the [simple blog tutorial](simple-blog-goal.html), we will
now create a basic _resolver_ (and briefly see how to adapt our
_actions_). To get started, in a `Resolver` module (`touch
bin/resolver.ml`), we’ll define a type (which can remain abstract)
that will describe the roots of our three contexts:


```ocaml
type t = 
  { source: Path.t
  ; target: Path.t
  ; server: Path.t
  }
```

We can now create a function to initialize our _resolver_, allowing us
to provide default arguments:

```ocaml
let make 
  ?(source_folder = Path.rel [])
  ?(target_folder = Path.rel ["_www"])
  ?(server_folder = Path.abs []) 
  () 
  = 
  { source = source_folder
  ; target = target_folder
  ; server = server_folder
  }
```

The general idea is to compute all of our paths from a value of type
`t`.  We can then define functions within submodules to resolve each
path.

For example, if we wanted to create a resolver for a site hosted on
the `gh-pages` branch of the project `my-project`, we might imagine
the following _resolver_:

```ocaml
# let my_resolver = 
    make ~server_folder:(Path.abs ["my-project"]) () ;;
val my_resolver : t = {source = ./; target = ./_www; server = /my-project}
```


### Source

We’ll start with the simplest submodule, `Source`.  First, we define a
function that lets us _easily_ access the root of the source:

<!-- $MDX skip -->
```ocaml
module Source = struct 
  let source_root { source; _ } = source
end
```

Now we can rebuild all the variables we introduced earlier in the blog
creation guide:


```ocaml
module Source = struct 
  let source_root { source; _ } = source
  
  (* Assets *)
  let assets res = Path.(source_root res / "assets")
  let images res = Path.(assets res / "images")
  let css res = Path.(assets res / "css")
  let templates res = Path.(assets res / "templates")
  
  (* Content *)
  let content res = Path.(source_root res / "content")
  let pages res = Path.(content res / "pages")
  let articles res = Path.(content res / "articles")
  let index res = Path.(content res / "index.md")
end
```

We’ve simply relocated the variables we defined on the fly throughout
the tutorial into a `Resolver.Source` module. The main advantage is
that the source of our various files is now **defined by the values we
provide to our _resolver_**, allowing us, for example, to condition
the source of our generator via the CLI.


### Target

We can perform the same exercise for the target. In the tutorial, we
calculated the target on the fly in each action. This time, we can
introduce a new submodule: `Resolver.Target`:


```ocaml
module Target = struct 
  let target_root { target; server; _ } = 
    Path.relocate ~into:target server
end
```

Here there’s a subtlety! One might think that, just like the `Source`
module, the root of the target is **simply** the `target` member.
However, if the server root isn’t `/`, we want to build the path
relative to the server root.

For example, using the _dummy resolver_ we created earlier (for the
project hosted on the GitHub Page `my-project`):


```ocaml
# Target.target_root my_resolver ;;
- : Path.t = ./_www/my-project
```

This little _hack_ allows us to remain consistent between the URLs on
our local server and how our site will be served in
production. Indeed, access to our site will be through
`localhost:port/my-project`.

We can now complete our module with the _ad-hoc_ targets we previously
used in our actions.


```ocaml
module Target = struct 
  let target_root { target; server; _ } = 
    Path.relocate ~into:target server
    
  let cache res = 
    Path.(target_root res / ".cache")
    
  let images res = 
    Path.(target_root res / "images")
    
  let style_css res = 
    Path.(target_root res / "style.css")
    
 
  let page res source = 
    let into = target_root res in
    source 
    |> Path.move ~into
    |> Path.change_extension "html"
    
  let article res source = 
    let into = Path.(target_root res / "articles") in
    source 
    |> Path.move ~into
    |> Path.change_extension "html"
    
  let index res = 
    Path.(target_root res / "index.html")
    
  let atom res = 
    Path.(target_root res / "atom.xml")
end
```

We can quickly verify that our _resolver_ works by trying to calculate
the target for the following article:


```ocaml
let my_first_article = 
   let open Path in
   Source.articles my_resolver / "my-first-article.md"
```

We can use `Target.article` and see that the calculated path correctly
takes the server root into account:

```ocaml
# let my_first_article_target = 
     Target.article my_resolver my_first_article ;;
val my_first_article_target : Path.t =
  ./_www/my-project/articles/my-first-article.html
```

We can now move on to the final step: the server.

### Server

Resolving links for the server is much simpler.  Indeed, we can
calculate a server path based on a standard target calculation.  We’ll
use the function
[`Path.trim`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Path/index.html#val-trim),
which removes a prefix from a path:


```ocaml
module Server = struct 
  let server_root { server; _ } = server
  
  let from_target res path = 
    let prefix = Target.target_root res in
    let into = server_root res in
    path 
    |> Path.trim ~prefix 
    |> Path.relocate ~into
end
```

We can test this using `my_first_article_target`:

```ocaml
# Server.from_target my_resolver my_first_article_target ;;
- : Path.t = /my-project/articles/my-first-article.html
```

Now that we’ve finalized our _resolver_, we can start using it!


## Using the Resolver

The first thing we’ll do is initialize our resolver in our program:

> Note that it would also be possible to configure the target and
> server root via CLI arguments.


```diff
- let program () =
+ let program resolver () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
   >>= copy_images
   >>= create_css
   >>= create_pages
   >>= create_articles
   >>= create_index
   >>= create_feed
   >>= Action.store_cache cache

 let () =
+  let resolver = Resolver.make () in
   match Sys.argv.(1) with
   | "server" -> 
     Yocaml_unix.serve 
        ~level:`Info 
        ~target:www 
        ~port:8000 
-       program
+       (program resolver)
   | _ | (exception _) -> 
      Yocaml_unix.run 
        ~level:`Debug 
-       program
+       (program resolver)
```

Next, we can pass our _resolver_ to our actions. We won’t do it for
every action, because if you can do it for **one action**, you can do
it for all:


```diff
-let create_css =
+let create_css resolver =
-  let css_path = Path.(www / "style.css") in
+  let css_path = Resolver.Target.style_css resolver in
+  let css = Resolver.Source.css resolver in
   let pipeline =
     let open Task in
     let+ () = track_binary
     and+ content =
       Pipeline.pipe_files ~separator:"\n"
         Path.[ css / "foo.css"; css / "reset.css"; css / "style.css" ]
     in
     content
   in
   Action.Static.write_file css_path pipeline

 let program resolver () =
   let open Eff in
-  let cache = Path.(www / ".cache") in
+  let cache = Resolver.Target.cache resolver in
   Action.restore_cache cache
   >>= copy_images
-  >>= create_css
+  >>= create_css resolver
   >>= create_pages
   >>= create_articles
   >>= create_index
   >>= create_feed
   >>= Action.store_cache cache
```

You can now update all your actions to use your freshly constructed
_resolver_!


## Conclusion

Even though this guide wasn’t particularly YOCaml-specific, we’ve seen
how to centralize path definitions! This centralization makes our
generator code more robust, potentially more configurable, and solves
the issue of sites not always being generated at a server root.

In practice, creating a _resolver_ is a common pattern among YOCaml
users. If you have other approaches or encodings, don’t hesitate to
share them with us!

