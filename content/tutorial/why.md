---
title: Why using YOCaml
description: The promotional part of YOCaml
synopsis:
  In this section, we will briefly — and somewhat subjectively — highlight 
  the reasons to choose YOCaml for building your next website.
date: 2025-08-28
updates:
  - key: 2025-08-28
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

The primary reason is straightforward: it is _highly enjoyable_.
Since YOCaml is a collection of _OCaml libraries_, building a
generator is based on **programming** rather than **configuration**.
Next, there are several reasons that _can be considered somewhat
objective_.

## As an (aspiring) OCaml user

If you are already using OCaml, YOCaml is built on top of _well-known_
OCaml libraries, including
[Cmarkit](https://ocaml.org/p/cmarkit/latest),
[Jingoo](https://ocaml.org/p/jingoo/latest), and libraries from the
[Mirage](https://mirage.io/) ecosystem, allowing you to work in a
familiar environment.

### For learning purposes

Learning functional programming can be intimidating, and while it is
easy to get caught up in the allure of _impressive encodings_, some
users occasionally find it lacking in _practical benefits_. YOCaml
makes use of several of these abstractions and tools — such as
[Applicatives](https://www.staff.city.ac.uk/~ross/papers/Applicative.pdf),
[Monads](https://homepages.inf.ed.ac.uk/wadler/papers/marktoberdorf/baastad.pdf),
[User-Defined Effects](https://ocaml.org/manual/5.3/effects.html),
[Profunctors](https://hackage.haskell.org/package/profunctors) and
[Arrows](https://www.cs.tufts.edu/~nr/drop/arrows.pdf), in very
practical contexts, allowing users to engage with the concrete and
useful application of these abstractions. _Using YOCaml is therefore
beneficial for learning functional programming_.

## Flexibility

Although _configuration-based_ tools are very popular, it is often
necessary to work around their intended usage to achieve specific
goals. YOCaml provides a collection of ergonomic tools for building a
wide variety of sites, allowing you to construct each step of the
process modularly, while minimizing the feeling of having to bend a
somewhat rigid _user path_.

### Some examples

Here is a list of some very different websites built with YOCaml, in
addition, this very website — also, of course, **written with YOCaml**
([source](https://github.com/yocaml/yocaml-www)):


- [Grim's web corner](https://gr-im.github.io): a very typical blog
  ([sources](https://github.com/gr-im/site))
- [xvw.lol](https://xvw.lol): A personal website with a more complex
  hierarchy ([sources](https://github.com/xvw/capsule))
- [Condor du Plateau](https://site.condor-du-plateau.fr/): A personal
  wiki with many pages following different templates
- [ring.muhokama](https://ring.muhokama.fun): A webring (inspired by
  the _smallweb_) ([sources](https://github.com/muhokama/ring))

## Efficiency

Performance was not the primary focus in the design of YOCaml—since
the emphasis was mainly on creating an _ergonomic API_ and ensuring
extensibility — YOCaml relies on efficient plugins and strives to
maintain **minimality**, as documented in [*Build Systems à la Carte:
Theory and
Practice*](https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf).
This principle, which aims to build only the artifacts that need to be
produced from one generation to the next, makes YOCaml a generator
with performance levels we are very satisfied with.

## On maintaining your website

Publishing on platforms may seem *pragmatic*, but social networks have
**standardized the web**, making it repetitive and tiring. Pages look
alike, sites like [Medium](https://medium.com/) prompt pop-ups, and
recommendation engines dominate the experience.

Building your own digital space with YOCaml — _or any tool_ — is
**fun, rewarding, and fully under your control**. You decide the
design, structure, and content. For interactivity, you can still share
your pages on [Digg](https://en.wikipedia.org/wiki/Digg) or [Hacker
News](https://news.ycombinator.com) and join the conversation—without
sacrificing your creative freedom.


_Please, Write your own personal website_.
