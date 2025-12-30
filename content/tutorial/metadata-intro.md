---
title: Introduction to Metadata
description: Understanding how to create and validate data
synopsis: 
  In the course on creating a blog, we used prebuilt _Archetypes_ such 
  as `Page`, `Article`, and `Articles`.
  In this guide, we will understand how to use the data description 
  language embedded in YOCaml to create data that can be validated, 
  from a variable data format, and that we can inject (or serialize) into 
  template engines such as _Mustach_ or _Jingoo_.
date: 2025-11-21
updates:
  - key: 2025-11-21
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

Indeed, in order **to be as generic as possible**, YOCaml provides a
library that allows you to **describe** arbitrary data
(which can be transformed into the description language of a
template engine, _arbitrarily_, or serialized into the form
of our choice) and to have it **validated**, from any arbitrary format.

## Validation and projection

When building a site generator, _whether static or not_, we generally
want to be able to attach _metadata_ to documents in order to control
how we want to render them (in HTML, for example). For that, we need
to be able to do three essential things:


- **Extract metadata from the document**: that is, _describe_ how the
  data is included in a document. In the previous examples, we used
  the [Front Matter
  approach](https://jekyllrb.com/docs/front-matter/), which simply
  consists of using `---` to separate the metadata from the document.
  
- **Validate the extracted metadata**: that is, ensure that the
  document actually contains the required data (and that it has the
  correct structure). In YOCaml, we use a specific format,
  [`Yocaml.Data.t`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-t).
  Metadata is first extracted according to an extraction strategy,
  then from a source format (for example `Yaml`, `ToML`, or `Sexp`),
  it is converted into the `Yocaml.Data.t` format. After that, we
  apply validations that allow us to convert our `Yocaml.Data.t` into
  a type of our choice.
  
- **Inject the validated data**: once our data is validated, we want
  to be able to _concretely_ generate our document, meaning transform
  our type into `Yocaml.Data.t` (and let YOCaml convert it into the
  language understood by the template engine).

You will have understood that, in order to be as generic as possible
and able to adapt to as many situations as possible, YOCaml uses a
very simple intermediate representation format that acts as a relay.

Here is a schematic example of how the hypothetical article generation
process works, from reading to writing:


![From metadata to artifact](/assets/images/data-flow.svg)


The generic handling of metadata is organized around several
interfaces (signatures):

- [`DATA_PROVIDER`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Required/module-type-DATA_PROVIDER/index.html)
  which allows you to describe a **description language** (such as
  Yaml or ToML). It explains how to go from the data type (Yaml or
  ToML) to
  [`Yocaml.Data.t`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-t).
  
- [`DATA_READABLE`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Required/module-type-DATA_READABLE/index.html)
  describes how to convert metadata expressed in a language defined by
  a `DATA_PROVIDER` into structured data.
  
- [`DATA_INJECTABLE`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Required/module-type-DATA_INJECTABLE/index.html)
  describes how to _normalize_ data so that it can be injected into a
  template.

In practice, when we **want to describe metadata**, we generally
define a module of the following form:

```ocaml
module type M = sig
  type t (* Metadata's type *)

  include Yocaml.Required.DATA_READABLE with type t := t
  include Yocaml.Required.DATA_INJECTABLE with type t := t
end
```

By including these two modules, the types described by the module can
be read as metadata from files and injected into templates to produce
artifacts. However, sometimes we may want to _distinguish_ between the
types we want to consume and the ones we want to inject, **which is
why there are two different interfaces**.

Now that we understand the main ideas, we will see how to **describe
data** (normalize it) and how to **validate data**.


## Naming conventions

Usually, we apply the following naming conventions:

- `to_data`: `t Data.converter`, which allows transforming arbitrary
  data into YOCaml’s data model.
  
- `from_data`: `t Data.validable`, which allows validating data from
  YOCaml’s data model into an arbitrary type.
  
- `normalize`: `t -> (string * Data.t) list`, which allows normalizing
  an arbitrary type into a template.
  
- `validate`: `t Data.validable`, which allows validating data from
  YOCaml’s data model into an arbitrary type (to be read from a file).
  
In the
[`Yocaml.Metadata`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Metadata/index.html#)
module there are functors to move from one representation to another.
However, generally, the `from_data` and `to_data` functions are mainly
used to build the data model and validate heterogeneous data, while
`normalize` and `validate` are used to work with file reading and
writing.

In the next section, we will see how to describe/project data while
respecting the YOCaml format.
