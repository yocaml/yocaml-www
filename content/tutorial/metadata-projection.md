---
title: From value to data
description: Understanding how to create data
synopsis: 
  Now that we have grasped the main lines of custom data handling
  (_archetypes_) with YOCaml, we can focus on how to transform arbitrary
  data into YOCaml’s data model. This section will mainly be used to
  inject data into the different template engines provided by YOCaml.

date: 2025-11-22
updates:
  - key: 2025-11-22
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# open Yocaml ;;
```

</div>

Before diving into data validation, we will see how to describe
generic data. All the **combinators** for constructing data are found
in the
[`Yocaml.Data`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html)
module.

Typically, a conversion function has the following type `'a
Yocaml.Data.converter` (that is, a function from `'a ->
Yocaml.Data.t`).  The module provides fairly straightforward
converters to transform OCaml values into `Data.t` values. The
[AST](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-t)
of the generic language is **very simple** (and seems sufficient to
describe a wide variety of data models). The AST fragments are divided
into two main categories:

- Simple types, such as `null`, `bool`, `int`, `float`, and `string`
- Composite types, such as `list` and `record`

This AST is **very similar** to the _simple_ representation of
[Yojson](https://ocaml.org/p/yojson/3.0.0/doc/yojson/Yojson/Basic/index.html#type-of-the-json-tree).
Indeed, **JSON** captures, from our point of view, quite well, in a
generic way, the concept of key-value pairs, which is used by ToML or
Yaml to describe data.

## Simple values

The conversion of _simple_ OCaml values into `Data.t` is fairly
_straightforward_; indeed, there are direct functions for this. For
example, to create the value `null`:

```ocaml
# Data.null ;;
- : Data.t = Data.Null
```

### Boolean projection

Converting OCaml booleans into `Data.t` booleans involves using the
function
[`Yocaml.Data.bool`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-bool):

```ocaml
# Data.bool true ;;
- : Data.t = Data.Bool true
```

```ocaml
# Data.bool false ;;
- : Data.t = Data.Bool false
```

### Number projection 

As with booleans, we can use the functions
[`Yocaml.Data.int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-int)
and
[`Yocaml.Data.float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-float):

```ocaml
# Data.int 42 ;;
- : Data.t = Data.Int 42
```

```ocaml
# Data.float 3.14 ;;
- : Data.t = Data.Float 3.14
```

### String projection

Once again, there is a direct function,
[`Yocaml.Data.string`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-string),
to convert an OCaml string:

```ocaml
# Data.string "Hello World";;
- : Data.t = Data.String "Hello World"
```

## Composing with projections

Building simple values is not enough to capture the diversity of
possible models. Fortunately, the data description API provides tools
to combine and structure data!

### Option projection

Thanks to
[`Yocaml.Data.null`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-null),
we can easily represent the `option` type using the function
[`Yocaml.Data.option`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-option):

```ocaml
# Data.option ;;
- : ('a -> Data.t) -> 'a option -> Data.t = <fun>
```

As the function's signature indicates, `option` allows us to transform
an arbitrary converter into a converter for options:

```ocaml
# Data.(option string) (Some "Hello World") ;;
- : Data.t = Data.String "Hello World"
```

```ocaml
# Data.(option int) None ;;
- : Data.t = Data.Null
```

> Note that options are
> [unboxed](https://www.janestreet.com/tech-talks/unboxed-types-for-ocaml/). This
> is not a decision made for _performance reasons_ but to align with
> the usual usage of key-value languages, such as JSON.

### List projection

In the same way as `option`, there is a combinator to construct lists:
[`Yocaml.Data.list_of`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-list_of):

```ocaml
# Data.list_of ;;
- : ('a -> Data.t) -> 'a list -> Data.t = <fun>
```

Just like with `option`, `list_of` allows us to transform an arbitrary
converter into a converter for lists:

```ocaml
# Data.(list_of string) [] ;;
- : Data.t = Data.List []
```

```ocaml
# Data.(list_of int) [1; 2; 3] ;;
- : Data.t = Data.List [Data.Int 1; Data.Int 2; Data.Int 3]
```

However, sometimes we may not want to describe _monomorphic_ lists. We
might want to describe heterogeneous lists, which is possible in our
AST because we can pack different types into one. There is the
function
[`Yocaml.Data.list`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-list),
which allows taking an arbitrary list of `Data.t` terms:

```ocaml
# Data.(list [int 12; bool true; string "Hello World"]) ;;
- : Data.t =
Data.List [Data.Int 12; Data.Bool true; Data.String "Hello World"]
```

## Record projections

Now that we have gone over all the primitive converters and
combinators for producing more complex values, such as lists or
options, it is time to look at a very versatile combinator:
[`Yocaml.Data.record`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-record)
.

```ocaml
# Data.record ;;
- : (string * Data.t) list -> Data.t = <fun>
```

Its operation is _quite simple_: we construct a record based on an
**associative list** that _associates_ a field (the string) with some
data. For example, if we wanted to describe a point, we could proceed
as follows:

```ocaml
let data_point ~x ~y = 
  let open Data in
  record [
    "x", int x
  ; "y", int y
  ]
```

```ocaml
# data_point ~x:12 ~y:57 ;;
- : Data.t = Data.Record [("x", Data.Int 12); ("y", Data.Int 57)]
```

Although its operation is quite simple, the `record` combinator allows
us to build a series of very practical tools to describe data as
precisely as possible!

### Tuple projection

Just as we can express _records_, we can easily describe _pairs_ of
data using
[`Yocaml.Data.pair`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-pair)

```ocaml
# Data.(pair string int) ("Hello", 10) ;;
- : Data.t = Data.Record [("fst", Data.String "Hello"); ("snd", Data.Int 10)]
```

As we can see, _pairs_ are described using _records_. And once we can
describe _pairs_, we can describe _triples_ and _quads_ (which
themselves are described in terms of _pairs_), therefore, _in terms of
records_:


```ocaml
# Data.(triple int float bool) (1, 2.0, true) ;;
- : Data.t =
Data.Record
 [("fst", Data.Int 1);
  ("snd", Data.Record [("fst", Data.Float 2.); ("snd", Data.Bool true)])]
```

```ocaml
# Data.(quad int float bool string) (1, 2.0, true, "foo") ;;
- : Data.t =
Data.Record
 [("fst", Data.Int 1);
  ("snd",
   Data.Record
    [("fst", Data.Float 2.);
     ("snd",
      Data.Record [("fst", Data.Bool true); ("snd", Data.String "foo")])])]
```

The advantage of using records _under the hood_ as the primitive
representation for complex data is that it allows for quick and easy
compatibility with less expressive languages (such as JSON, ToML, or
Yaml).

### Sum type projection

In the same way that we can use `record` to describe _pairs_, we can
use `record` to describe [sum/variant
types](https://ocaml.org/docs/basic-data-types#variants).  For
example, the _most primitive variant_ is the
[`Either`](https://ocaml.org/manual/5.3/api/Either.html) type, which,
just as a _pair_ allows us to describe triples (and then quads),
`Either` is sufficient to describe any variant:

```ocaml
# Yocaml.Data.either ;;
- : ('a -> Data.t) -> ('b -> Data.t) -> ('a, 'b) Either.t -> Data.t = <fun>
```

The combinator works similarly to `option`. For example:

```ocaml
# Data.(either int bool) (Either.Left 10) ;;
- : Data.t =
Data.Record [("constr", Data.String "left"); ("value", Data.Int 10)]
```

```ocaml
# Data.(either int bool) (Either.Right false) ;;
- : Data.t =
Data.Record [("constr", Data.String "right"); ("value", Data.Bool false)]
```

As we can see, **just like with tuples**, the _under the hood_
representation of variants is described using `record`.

Additionally, there is a function _dual_ to `record`:
[`Yocaml.Data.sum`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-sum),
which allows handling generic sums:

```ocaml
# Data.sum ;;
- : ('a -> string * Data.t) -> 'a -> Data.t = <fun>
```

The function `sum f x` will _analyze_ `x` and return the pair
corresponding to the **constructor** and the **value** associated with
that constructor. For example, `either` is described based on `sum`:

```ocaml
# let my_either if_left if_right = 
    Data.sum (function 
      | Either.Left x   -> "left",  if_left x
      | Either.Right x  -> "right", if_right x
    ) ;;
val my_either :
  ('a -> Data.t) -> ('b -> Data.t) -> ('a, 'b) Either.t -> Data.t = <fun>
```

The `sum` combinator is very generic and also allows, for example, to
map sums described using polymorphic variants. For example:

```ocaml
# let f = 
   Data.sum (function
     | `A   -> "foo", Data.null
     | `B b -> "bar", Data.bool b
     | `C s -> "str", Data.string s
     | `D l -> "list", Data.list_of Data.float l
    ) ;;
val f :
  ([< `A | `B of bool | `C of string | `D of float list ] as '_weak1) ->
  Data.t = <fun>
```

With **primitive types**, **products** (`record`), and **sums**
(`sum`), it is possible to describe almost any kind of data type!

## Built-in projection

Some _built-in_ YOCaml types provide conversion functions. For example,
[`Yocaml.Data.path`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-path),
which allows _normalizing_ file paths, and
[`Yocaml.Datetime.normalize`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Archetype/Datetime/index.html#val-normalize),
which transforms dates (adding lots of information):

```ocaml
# Datetime.normalize (Datetime.dummy) ;;
- : Data.t =
Yocaml__.Data.Record
 [("year", Yocaml__.Data.Int 1970); ("month", Yocaml__.Data.Int 1);
  ("day", Yocaml__.Data.Int 1); ("hour", Yocaml__.Data.Int 0);
  ("min", Yocaml__.Data.Int 0); ("sec", Yocaml__.Data.Int 0);
  ("has_time", Yocaml__.Data.Bool false);
  ("day_of_week", Yocaml__.Data.Int 3);
  ("repr",
   Yocaml__.Data.Record
    [("month", Yocaml__.Data.String "jan");
     ("datetime", Yocaml__.Data.String "1970-01-01 00:00:00");
     ("date", Yocaml__.Data.String "1970-01-01");
     ("time", Yocaml__.Data.String "00:00:00");
     ("day_of_week", Yocaml__.Data.String "thu")])]
```

By convention, the `to_data` function, of type `t -> Data.t` (or `t
Data.converter`), describes projection functions that can be composed
with other projectors.


## A Real World Example

Now that we have seen how to describe arbitrary data, here is an
exercise aimed at creating a set of projection functions for the
following modules:

```ocaml
module Gender = struct 
  type t =
    | Male 
    | Female 
    | Other of string
end

module User = struct 
  type t = {
    username: string
  ; firstname: string option
  ; lastname: string option
  ; age: int
  ; gender: Gender.t
  ; identities: t list
  }
  
  let make 
    ?firstname 
    ?lastname 
    ?(identities = []) ~age ~gender username = {
      username
    ; firstname
    ; lastname
    ; age
    ; gender
    ; identities
    }
  
end
```

The `identities` field is mainly used to see how to work with
recursive types.

### Projecting the gender

First, we will start with the simplest task: projecting values of type
`Gender.t`. To do this, we will use the `sum` function, which we saw
earlier:

```ocaml
module Gender = struct 
  type t =
    | Male 
    | Female 
    | Other of string
    
  let to_data = 
    let open Yocaml.Data in 
    sum (function 
      | Male    -> "male",   null
      | Female  -> "female", null
      | Other s -> "other", string s 
    )
end
```

We can now test our projection:


```ocaml
# Gender.to_data Gender.Male ;;
- : Data.t =
Data.Record [("constr", Data.String "male"); ("value", Data.Null)]
```

```ocaml
# Gender.to_data Gender.Female ;;
- : Data.t =
Data.Record [("constr", Data.String "female"); ("value", Data.Null)]
```

```ocaml
# Gender.to_data Gender.(Other "fluid") ;;
- : Data.t =
Data.Record [("constr", Data.String "other"); ("value", Data.String "fluid")]
```

As we can see, the translation is fairly straightforward! Let's now
move on to normalizing a user.


### Projecting a user

Now we will _primarily_ use `record` to describe the projection of a
`User.t`. The only nuance compared to previous examples is that we
will define our projection as **recursive** to handle the case of the
_user list_, and we will use our freshly constructed `Gender.to_data`
function:

```ocaml
module User = struct 
  type t = {
    username: string
  ; firstname: string option
  ; lastname: string option
  ; age: int
  ; gender: Gender.t
  ; identities: t list
  }
  
  let make 
    ?firstname 
    ?lastname 
    ?(identities = []) ~age ~gender username = {
      username
    ; firstname
    ; lastname
    ; age
    ; gender
    ; identities
    }
    
  let rec to_data 
    { username; firstname; lastname; 
      age; gender; identities } 
  = 
    let open Yocaml.Data in
    record [
      "username",   string username
    ; "firstname",  option string firstname
    ; "lastname",   option string lastname
    ; "age",        int age
    ; "gender",     Gender.to_data gender
    ; "identities", list_of to_data identities
    ]
  
  
end
```

We can create a few users to test our projection:

```ocaml
let xvw1 = User.make ~age:36 ~gender:Gender.Male "xvw"
let xvw2 = 
  User.make
    ~identities:[xvw1; xvw1]
    ~firstname:"Xavier"
    ~lastname:"Van de Woestyne"
    ~age:36
    ~gender:(Gender.Other "male")
    "xvw2"
```

And we can use them: 

```ocaml
# User.to_data xvw2 ;;
- : Data.t =
Data.Record
 [("username", Data.String "xvw2"); ("firstname", Data.String "Xavier");
  ("lastname", Data.String "Van de Woestyne"); ("age", Data.Int 36);
  ("gender",
   Data.Record
    [("constr", Data.String "other"); ("value", Data.String "male")]);
  ("identities",
   Data.List
    [Data.Record
      [("username", Data.String "xvw"); ("firstname", Data.Null);
       ("lastname", Data.Null); ("age", Data.Int 36);
       ("gender",
        Data.Record [("constr", Data.String "male"); ("value", Data.Null)]);
       ("identities", Data.List [])];
     Data.Record
      [("username", Data.String "xvw"); ("firstname", Data.Null);
       ("lastname", Data.Null); ("age", Data.Int 36);
       ("gender",
        Data.Record [("constr", Data.String "male"); ("value", Data.Null)]);
       ("identities", Data.List [])]])]
```

It is possible to change the handling of the `gender` field using the
function
[`Yocaml.Data.into`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#val-into):

```diff
let rec to_data 
    { username; firstname; lastname; 
      age; gender; identities } 
  = 
    let open Yocaml.Data in
    record [
      "username",   string username
    ; "firstname",  option string firstname
    ; "lastname",   option string lastname
    ; "age",        int age
-   ; "gender",     Gender.to_data gender
+   ; "gender",     into (module Gender) gender
    ; "identities", list_of to_data identities
    ]
```

<div class="hidden-toplevel">

```ocaml
module User = struct 
  type t = {
    username: string
  ; firstname: string option
  ; lastname: string option
  ; age: int
  ; gender: Gender.t
  ; identities: t list
  }
  
  let make 
    ?firstname 
    ?lastname 
    ?(identities = []) ~age ~gender username = {
      username
    ; firstname
    ; lastname
    ; age
    ; gender
    ; identities
    }
    
  let rec to_data 
    { username; firstname; lastname; 
      age; gender; identities } 
  = 
    let open Yocaml.Data in
    record [
      "username",   string username
    ; "firstname",  option string firstname
    ; "lastname",   option string lastname
    ; "age",        int age
    ; "gender",     into (module Gender) gender
    ; "identities", list_of to_data identities
    ] 
end
```

</div>

Now that we have seen how to construct data, which can later be
injected into templates, we will first look at how to **validate
data**.
