---
title: Introduction
description: A conceptual introduction to YOCaml
synopsis:
  Welcome to the **YOCaml** user guide!
  This page is quite _marketing-oriented_.
date: 2025-08-27
updates:
  - key: 2025-08-29
    value:
      description: Comprehensive rewriting
      authors: ["xvw <xaviervdw@gmail.com>"]
  - key: 2025-08-27
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

### What is YOCaml

YOCaml is a _framework_ used to describe _build systems_ in
[OCaml](https://ocaml.org), released under [GPL3 license
](https://raw.githubusercontent.com/xhtmlboi/yocaml/refs/heads/main/LICENSE),
with an _API_ suited for creating [static site
generators](https://en.wikipedia.org/wiki/Static_site_generator). Unlike
[Hugo](https://gohugo.io/), [Jekyll](https://jekyllrb.com/) or
[Zola](https://www.getzola.org/), which provide a _CLI_, YOCaml is
closer to [Hakyll](https://jaspervdj.be/hakyll/), as it imposes **no
structure**, requiring you to build your generator step by step. This
offers the opportunity to create diverse projects such as a [personal
blog](https://gr-im.github.io), a [personal wiki](https://maiste.fr/),
[more experimental sites](https://site.condor-du-plateau.fr/), a
[webring](https://ring.muhokama.fun) or even this documentation
website.


#### Written in OCaml

YOCaml is, as its name suggests, written in the wonderful language
[OCaml](https://ocaml.org), a programming language that is
**statically typed** (with type inference), **functional**,
**imperative**, and **object-oriented**, and that features a rich
module system. While the simplest reason we wrote YOCaml in OCaml is
probably that _we like OCaml_, the language’s grammatical and
conceptual flexibility made it easier to design an API that we find
**expressive**. In addition, OCaml is a high-performance language with
a rich ecosystem — if you want to convince yourself to use OCaml, we
invite you to read [Why I chose OCaml as my primary
language](https://xvw.lol/en/articles/why-ocaml.html).


##### Adhering to the ecosystem

YOCaml was designed in a _very modular_ way, allowing us to take
advantage of the OCaml ecosystem. As a result, even though YOCaml is
packaged with a set of _standard plugins_, the core API makes it
fairly easy to integrate other libraries. For example,
[users](https://github.com/Psi-Prod/Capsule) have
[requested](https://github.com/xhtmlboi/yocaml/issues/38) support for
[Gemtext](https://gmi.sbgodin.fr/htmgem/docs/tutogemtext-en.gmi), in
order to serve their site over
[Gemini](https://en.wikipedia.org/wiki/Gemini_(protocol)). No changes
were required in YOCaml’s core, _demonstrating its flexibility_.


### Easy deployment

One of the **great strengths** of statically generated sites is that
they are very easy to deploy. In fact, a simple static server is
enough! However, YOCaml goes further: thanks to the
[Mirage](https://mirage.io/) project, it is possible to directly
generate documents using a _Git repository_ as a file system
(compatible with [GitHub Pages](https://pages.github.com/)) and serve
them statically. For example, by using
[Unipi](https://github.com/robur-coop/unipi), you can build an
**operating system (unikernel) designed to statically serve your
site** with great ease!


