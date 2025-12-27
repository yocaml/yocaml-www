---
title: Goals & Introduction
description: The goal and the introduction of the tutorial
synopsis: 
  In this tutorial, we’ll build a complete, usable blog step by 
  step using the YOCaml API and some of its plugins.
date: 2025-09-03
updates:
  - key: 2025-09-03
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>"]
---

After reviewing the key concepts [in the previous
section](/tutorial/key-concepts.html), it is time to put them into
practice by building, step by step, a fully functional, statically
generated blog that includes:

- articles (of course) converted from
  [Markdown](https://en.wikipedia.org/wiki/Markdown) to HTML
- pages (also written in Markdown and converted to HTML)
- an [ATOM](https://en.wikipedia.org/wiki/Atom_(web_standard))
  syndication feed
- a development server

The blog will have its own stylesheet and templates, using the
[Jingoo](https://tategakibunko.github.io/jingoo/templates/templates.en.html)
template engine (inspired by
[Jinja2](https://github.com/pallets/jinja/)).


### Disclaimer

The first thing to note is that this guide is a **tutorial on using
YOCaml**, not on using Jingoo, HTML, CSS or even OCaml. So feel free
to use an existing template or create your own if you are a designer
and this guide also assumes that you have at least **a superficial
knowledge of OCaml**.


#### About Code Organization

For simplicity, most of the code for our generator will be written in
a single module, `blog.ml`. However, as mentioned several times,
YOCaml is just a collection of regular packages, so **you are free to
organize your code however you like**.


### Starting point

The entire tutorial assumes that the [Setup](/tutorial/setup.html)
section has been completed, and we will be building upon the `blog`
project we created earlier. We assume the directory is organized as
follows:


```shell
├── _opam
├── _build
├── bin
│   ├── blog.ml
│   └── dune
├── blog.opam
├── .ocamlformat
├── dune-project
└── README.md
```

#### Data Organization

Before we start writing code, let's organize our directory. To do
this, we will create several folders to hold the files needed to build
our site.


```shell
mkdir -p assets/css
mkdir assets/images
mkdir assets/templates
mkdir -p content/articles
mkdir content/pages
```

This should structure our directory as follows:

```diff
  ├── _opam
  ├── _build
+ ├── assets
+     ├── css
+     ├── images
+     └── templates

  ├── bin
  │   ├── blog.ml
  │   └── dune
+ ├── content
+     ├── articles
+     └── pages
  ├── blog.opam
  ├── .ocamlformat
  ├── dune-project
  └── README.md
```

The content of our site (mainly Markdown files) will go in
`content/`. We create two subdirectories to store pages and articles,
respectively. Our _assets_ will be stored in the `assets/` directory,
which will contain our CSS files, images, and templates.

Our goal is to generate the complete site in the `_www` directory,
which we should not create ourselves, as YOCaml will handle it!


#### Git Repository

It is recommended to use a Git repository to track the progress of
your development and, potentially, to take advantage of services like
[GitHub](https://github.com) or [GitLab](https://gitlab.com) for CI
and static page hosting to automate deployment.

If you choose to use a repository, don’t forget to update the
`dune-project` file accordingly (and run `dune build` to rebuild your
OPAM file). You can also add a
[.gitignore](https://www.toptal.com/developers/gitignore/api/ocaml)
file tailored for OCaml, including the `_www` directory to ignore the
generated output.


### Setting Up the Cache

As we saw earlier, YOCaml uses a cache to track dynamic
dependencies. We can clear the contents of `blog.ml` and replace it
with the following code:

<!-- $MDX skip -->
```ocaml
open Yocaml

let www = Path.rel [ "_www" ]

let program () =
  let open Eff in
  let cache = Path.(www / ".cache") in
  Action.restore_cache cache 
  >>= Action.store_cache cache

let () = Yocaml_unix.run ~level:`Debug program
```

- We start by describing a path that will be the directory where we
  create/move all our files, here `www`.
  
- We create various shortcuts to quickly reference the different
  directories we just created (to get familiar with the Path API).

- Since no actions are written yet, we simply read the cache and then
  save it. Later, our **Actions** will be placed between the cache
  restoration and storage steps.
  
Here is an example of adding some action in the code:

```diff
 open Yocaml
  
 let www = Path.rel [ "_www" ]
  
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
+  >>= a_first_action
+  >>= a_second_action (* etc. *)
   >>= Action.store_cache cache

 let () = Yocaml_unix.run ~level:`Debug program
```

  
_Let’s move on to the next step!_

