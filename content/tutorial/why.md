---
title: Why use YOCaml
description: The promotional part of YOCaml
synopsis:
  Another page with a marketing focus (but also somewhat presented as a 
  _manifesto_) aimed at highlighting the advantages — somewhat subjective — 
  of using YOCaml.

date: 2025-08-28
updates:
  - key: 2025-08-29
    value:
      description: Comprehensive rewriting
      authors: ["xvw <xaviervdw@gmail.com>"]
  - key: 2025-08-28
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

In this _guide_, we will explore why you should use **YOCaml**. It is
organized around three main axes:

- the (subjective) _strengths_ of YOCaml
- educational reasons
- an ideological perspective

Of course, the first obvious reason to use YOCaml would be that you
**already know OCaml (and love the language)**, want to create a
personal site, and don’t want to _reinvent the wheel_—and yes,
building _your own site generator_ is a canonical exercise for an
OCaml developer.


## Subjective strengths

All of the strengths listed here are derived from our experience using
YOCaml over several months on different projects. Hence the **highly
subjective** nature of this section.


### Performance and efficiency

Even though we don’t have concrete benchmarks, as users we have had
relatively few reasons to be frustrated by YOCaml’s page generation
speed. Moreover, the YOCaml engine **aims for minimality** — meaning
it only rebuilds pages that need to be updated from one modification
to the next.

In addition, OCaml compiles **extremely quickly** and is very stable,
making it possible to build a generator that remains reliable over
time!


### Flexibility and diversity without "hacks"

Since YOCaml only **enforces a computation model**, it doesn’t impose
any limits on organization, or the types of data to consume and
produce. This genericity allows YOCaml to be used in a fairly standard
way whenever you want to read and generate files, enabling the
creation of almost any type of statically generated site.

YOCaml emphasizes genericity, allowing users not to be locked into
pre-designed page archetypes. This choice was made without sacrificing
possible static guarantees and _type safety_ by grounding the
computation model in an expressive yet strict API.


## As an educational tool

Although YOCaml is probably not the ideal library for discovering and
learning OCaml, it offers opportunities to explore sometimes
bewildering concepts of functional programming. Indeed, YOCaml
attempts to make practical and meaningful use of
[Monads](https://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf),
[Applicative
Functors](https://www.staff.city.ac.uk/~ross/papers/Applicative.pdf),
[User-Defined Effects](https://ocaml.org/manual/5.3/effects.html),
[Profunctors](https://hackage.haskell.org/package/profunctors), and
[Arrows](https://www.cs.tufts.edu/~nr/drop/arrows.pdf). As such, using
YOCaml provides a concrete way to engage directly with intimidating
abstractions in functional programming.


### Learn OCaml

If you’re not familiar with OCaml but find the arguments in this
section convincing, here are some resources to learn OCaml and come
back here when you’re ready to build your personal site, **with
YOCaml**:

- [OCaml Programming: Correct + Efficient +
  Beautiful](https://cs3110.github.io/textbook/cover.html)
- [Real World OCaml](https://dev.realworldocaml.org/)
- [Using, Understanding, and Unraveling The OCaml
  Language](https://gallium.inria.fr/~remy/cours/appsem/ocaml.pdf)

## Against the "boring normalized web"

Although the web is an amazing tool, over time — often for legitimate
reasons — it has become drastically standardized. Indeed, with the
proliferation of devices, we have moved from a patchwork of chaotic
personal sites to increasingly similar ones! Fortunately, there is a
resurgence of fun in [personal
initiatives](https://webring.xxiivv.com/) or more [institutionalized
projects](https://neocities.org/). YOCaml fits right into this trend!


### Behind the platforms

Platforms like [Medium](https://medium.com/) and
[Dev.to](https://dev.to/) have marginalized the practice of
maintaining your own websites. _What a shame_. We imagine the main
reasons were community consolidation; however, many articles have been
held hostage (at least by Medium), with pop-ins and other
annoyances. One way to fight _this terrible centralization_ of
information is to maintain your own [digital
garden](https://maggieappleton.com/garden-history/)! And YOCaml is
perfectly suited for that!


### Templates and tools

Since YOCaml requires starting from a blank slate (in terms of
architecture, templates, and organization), it may seem
impractical. One of the main reasons behind this choice is to avoid
pushing users into the same templates and architectures. Indeed, we
want YOCaml to be an excuse to reinvent the wheel — at least for your
own website! Having a _CLI_ that _bundles_ a specific usage and
templates is therefore not on the agenda (or at least not in the form
of an official YOCaml package).


## Why Not Use YOCaml

There are several perfectly valid reasons why you might **choose not
to use YOCaml**. To save you time, here’s a list:

- **You don’t like OCaml**: that’s unfortunate! But since YOCaml is an
  OCaml DSL, disliking OCaml makes using YOCaml pretty much
  unthinkable.

- **You want something pre-bundled**: YOCaml’s goal is not to restrict
  users’ creativity but to encourage them to build their own site,
  following the architecture and model of their choice. It is
  therefore not packaged with a generator that enforces a file
  structure or imposes templates.
  
- **You want to build a dynamic application**: this, of course,
  applies to all static site generators. If you need heavy interaction
  between users and a server and are not inclined to use
  [JamStack](https://sdtimes.com/webdev/jamstack-brings-front-end-development-back-into-focus/),
  we suggest looking into
  [Ocsigen](https://ocsigen.org/home/intro.html), [Vif &
  Hurl](https://github.com/robur-coop/vif),
  [Dream](https://aantron.github.io/dream/), or
  [Mirage](https://mirage.io/) (all OCaml frameworks).

If none of these reasons apply to you, you’re ready to start using
YOCaml!
