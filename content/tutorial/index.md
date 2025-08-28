---
title: Introduction
description: A conceptual introduction to YOCaml
synopsis:
  Welcome to the **YOCaml** tutorial. [YOCaml](https://github.com/xhtmlboi/yocaml) 
  is a **highly flexible** static site generator, developed in and 
  powered by [OCaml](https://ocaml.org).
  This guide will walk you step by step through the process of using YOCaml 
  to create and manage web pages.
date: 2025-08-27
updates:
  - key: 2025-08-27
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

YOCaml is a *framework* for building [Static Site
Generator](https://en.wikipedia.org/wiki/Static_site_generator), *in
OCaml*.  In other words, it is a *build system* (similar to
[Dune](https://dune.build)), but with an API specifically tailored for
generating text files. It was designed with a strong focus on
extensibility, so that potential users are not locked into a
predefined structure. It also aims to leverage the various features
provided by the OCaml language, including its **module system**,
**strong type system** and **functional programming features**.

YOCaml simplifies content processing, templating, and site generation,
making it a great choice for developers who want a statically typed
and functional approach to static site generation. Conceptually, it is
fairly close to version 3 of [Hakyll](https://jaspervdj.be/hakyll/), a
generator written in [Haskell](https://www.haskell.org/).

### About the tutorial

Unlike some generators, such as [Jekyll](https://jekyllrb.com/) or
[Hugo](https://gohugo.io/) — which focus on configuring a pre-built
binary — YOCaml provides a **library-based approach**, giving you the
tools to build and customize your own static site generator (like
Hakyll). This explains the depth and detail of this tutorial.

#### A note on OCaml

The _framework_ nature of YOCaml requires writing OCaml code to build
your own generator. As such, this tutorial assumes that readers have
at least a basic understanding of OCaml and its core concepts.  If you
are not familiar with OCaml and want to understand the benefits of the
language, we invite you to read ["_Why I chose OCaml as my primary
language_"](https://xvw.lol/en/articles/why-ocaml.html).

#### OCaml resources

Fortunately, OCaml offers excellent resources. Here is some
[guides](https://ocaml.org/docs/formatting-text),
[books](https://ocaml.org/books), for learning the language
quickly. Here is a selection of three comprehensive resources:

- [OCaml Programming: Correct + Efficient +
  Beautiful](https://cs3110.github.io/textbook/cover.html)
- [Real World OCaml](https://dev.realworldocaml.org/)
- [Using, Understanding, and Unraveling The OCaml
  Language](https://gallium.inria.fr/~remy/cours/appsem/ocaml.pdf)
