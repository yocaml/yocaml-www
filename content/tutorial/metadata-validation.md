---
title: From data to values
description: Understanding how to validate data
synopsis: 
  Now that we can _create data_, we can now focus on data validation,
  which will allow us to read metadata attached to a document!

date: 2025-12-11
updates:
  - key: 2025-12-11
    value:
      description: "First version"
      authors: ["xvw <xaviervdw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
let pp_errors f ppf k = Yocaml.Nel.pp f ppf k
```

```ocaml
# open Yocaml ;;
# #install_printer pp_errors ;;
```

</div>


As with [creation](metadata-projection.html), data validation consists
of composing a **set of combinators** found in the
[`Yocaml.Data.Validation`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html)
module. We previously saw that projectable data of type `t` had the
type [`t
Yocaml.Data.converter`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-converter).
In the same way, YOCaml exposes two types to describe validations:

- [`('a, 'b)
  Yocaml.Data.validator`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-converter),
  which describes a function. (The notion of validation is expressed
  using the well-known
  [Result](https://ocaml.org/manual/5.2/api/Result.html) type from the
  OCaml standard library.)
  
- [`'a
  Yocaml.Data.validable`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-validable),
  which is a _specialized_ version of `validator`, but takes as an
  argument a value of type `Yocaml.Data.t` and attempts to convert it
  into an `'a`.

Usually, YOCaml handle the conversion of metadata from a document into
values of type `Yocaml.Data.t`. This is generally the role of the
[`DATA_PROVIDER`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Required/module-type-DATA_PROVIDER/index.html)
module, which is passed to functions whose purpose is to extract data
associated with a document. So our task is to transform values of type
`Yocaml.Data.t` (which is, broadly speaking, an *untyped
representation*) into the representation of our choice!

> There is **an interesting duality** between **conversion** to
> `Yocaml.Data.t` and **validation** from `Yocaml.Data.t`. Indeed,
> conversion is **a total function**: for any value that can be
> serialized, **there exists a representation**, so conversion should
> never fail.  
> Validation, however, starts from *untyped* information and **may
> potentially fail**, which makes validation **a partial function**.
> In a way, **converting** amounts to *packing* type information,
> while **validating** amounts to *unpacking*, or restoring, that type
> information.


## Simple values

Before validating complex and structured data, which will often be the
case when our data comes from documents, we will first see how to
validate simple data.  The goal of these validations will be **to
attempt to convert a `Yocaml.Data.t` value into a concrete OCaml
value**.


### A first example, boolean validation

First, we will create a value and then observe it with its
**associated validator**:
[`Yocaml.Data.Validation.bool`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-bool).


```ocaml
# Data.bool true |> Data.Validation.bool ;;
- : bool Data.Validation.validated_value = Ok true
```

You can do the same with `false`:

```ocaml
# Data.bool false |> Data.Validation.bool ;;
- : bool Data.Validation.validated_value = Ok false
```

We can see that validated values are wrapped in a `Result` and
_return_ their original types. But what happens if we try to validate
an unlikely or incorrect piece of data?


#### When validations fail

There are multiple reasons why a validation can fail, which are captured
by [the errors exposed by the `Yocaml.Data.Validation` module](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#type-value_error).  
A common error that can occur is simply that the value being validated
does not have the correct _shape_. For example, if I try to validate
an integer as a boolean.


```ocaml
# Data.int 42 |> Data.Validation.bool ;;
- : bool Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "bool"; given = Data.Int 42})
```

One might imagine that **any non-zero integer** would return `true`;
however, YOCaml tries, as much as possible, to avoid implicit
conversions. That said, we will see later that it is possible to
compose validators to handle multiple cases.


###### A bit more about implicit conversions

In principle, the fact that YOCaml tries to avoid implicit conversions
as much as possible does not mean that they do not exist at
all. Indeed, the different languages used to describe data (Sexp,
JSON, ToML, YAML, etc.) have varying levels of expressiveness (for
example, Sexp notably has fewer data types than ToML). The
`DATA_PROVIDER` modules, whose role is to convert data from these
different languages into `Yocaml.Data.t`, sometimes take liberties in
how they interpret a value as `Yocaml.Data.t`. This is why some
validation functions can be _a bit lax_ at times.


### Numbers validation

Unsurprisingly, number validation is very similar to boolean validation.  
We can use the two observation functions
[`int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-int)
and
[`float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-float)!
As with booleans, we will create data _of the correct shape_ and pass
it to our observation functions:

```ocaml
# Data.int 42 |> Data.Validation.int ;;
- : int Data.Validation.validated_value = Ok 42
```

You can do the same with `float`:

```ocaml
# Data.float 42.3 |> Data.Validation.float ;;
- : float Data.Validation.validated_value = Ok 42.3
```

And just like with booleans, we can quickly convince ourselves of the
reliability of the validation functions by trying to validate data
that is objectively irrelevant:


```ocaml
# Data.bool true |> Data.Validation.int ;;
- : int Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "int"; given = Data.Bool true})
```

#### Lax validation of numbers

Since JSON (through JavaScript's somewhat questionable primitive
types) does not specify a distinction between floats and integers,
YOCaml validation is a bit _lax_, allowing integers to be treated as
floats and vice versa:


```ocaml
# Data.float 42.14 |> Data.Validation.int ;;
- : int Data.Validation.validated_value = Ok 42
```

```ocaml
# Data.int 42 |> Data.Validation.float ;;
- : float Data.Validation.validated_value = Ok 42.
```

In practice, YOCaml generally does a good job of distinguishing
integers from floats during the `DATA_PROVIDER` conversion
phase. However, we are not completely immune to dubious inference,
hence this caution.

> OCaml has other representations of integers,
> [int64](https://ocaml.org/manual/5.4/api/Int64.html),
> [int32](https://ocaml.org/manual/5.4/api/Int32.html),
> [nativeint](https://ocaml.org/manual/5.4/api/Nativeint.html), etc.  
> We will see later how to build validators for these different integer
> representations (which are not _supported by default_ in YOCaml, as
> their use seemed marginal for document metadata).


### String validation

As with the previous types, `string` comes with its observation
function
[`Yocaml.Data.Validation.string`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-string). The
only difference compared to the previous validators is the presence of
the `strict` flag, which controls whether other data types can be
considered as strings.


```ocaml
# Data.string "Hello World" |> Data.Validation.string ;;
- : string Data.Validation.validated_value = Ok "Hello World"
```

If we try to observe a value of a type that does not match, just like
before, the validation will return an error:


```ocaml
# Data.int 34 |> Data.Validation.string ;;
- : string Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "strict-string"; given = Data.Int 34})
```

However, it is possible to _relax_ this constraint for cases where,
for example, the string `"true"` might have been converted to a
boolean, and we want to treat it as a string. To do this, we can set
the `strict` flag to `false`:


```ocaml
# Data.bool true |> Data.Validation.string ~strict:false ;;
- : string Data.Validation.validated_value = Ok "true"
```

Now that we have seen the basics of validation for _simple_ data, just
like with projections, let's look at more complex cases by composing
validators to validate more complex types such as lists or options.


## Composing with validation

As with projections, validating simple data is a good first step, but
now we want to be able to describe the validation of more complex
data!


### Option validation

As with projections, we can easily validate an option (in other words,
conditionally run a validator if a value exists or not). We can use
the function
[`Yocaml.Data.Validation.option`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-option):


```ocaml
# Data.Validation.option ;;
- : (Data.t -> 'a Data.Validation.validated_value) ->
    Data.t -> 'a option Data.Validation.validated_value
= <fun>
```

This allows us to _lift_ a standard validator into an option
validator. For example, with no value:


```ocaml
# Data.option (Data.int) None |> Data.Validation.(option int) ;;
- : int option Data.Validation.validated_value = Ok None
```

And with a value:

```ocaml
# Data.option (Data.int) (Some 10) |> Data.Validation.(option int) ;;
- : int option Data.Validation.validated_value = Ok (Some 10)
```

**Warning**: if a value exists but does not satisfy the validator, the
validation function will fail! The purpose of the option validator is
not to short-circuit a validation pipeline. For example, this function
will return an error:


```ocaml
# Data.option (Data.int) (Some 10) |> Data.Validation.(option string) ;;
- : string option Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "strict-string"; given = Data.Int 10})
```

### List validation

As with `option`, we have a validator that allows us to _lift_ a
standard validator into one that operates on lists, and
unsurprisingly, this is
[`Yocaml.Data.Validation.list_of`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-list_of).



```ocaml
# Data.Validation.list_of ;;
- : (Data.t -> 'a Data.Validation.validated_value) ->
    Data.t -> 'a list Data.Validation.validated_value
= <fun>
```

For example, we are going to validate a list of optional integers (and
yes, we are anticipating a bit the composition of validators):

```ocaml
# Data.(list_of (option int)) 
     [None; Some 10; Some 12; None; Some 43]
  |> Data.Validation.(list_of (option int)) ;;
- : int option list Data.Validation.validated_value =
Ok [None; Some 10; Some 12; None; Some 43]
```

If, on the other hand, one or more fields do not satisfy the
validators, **all errors are reported**:


```ocaml
# Data.(list [bool true; null; string "foo"; int 14]) 
  |> Data.Validation.(list_of (option int)) ;; 
- : int option list Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_list
   {Yocaml.Data.Validation.errors =
     (2,
      Data.Validation.Invalid_shape
       {Yocaml.Data.Validation.expected = "int"; given = Data.String "foo"})
     (0,
      Data.Validation.Invalid_shape
       {Yocaml.Data.Validation.expected = "int"; given = Data.Bool true});
    given = [Data.Bool true; Data.Null; Data.String "foo"; Data.Int 14]})
```

The error is a bit _verbose_ and hard to read, but don’t worry—with
YOCaml, it is [reported in a more readable
way](https://github.com/xhtmlboi/yocaml/pull/113)!


## Record Validation

As usual, all metadata attached to a document is structured as a
record.  This is probably the most important section of this tutorial.
As with other validations, record analysis is associated with an
observation function:
[`Yocaml.Data.Validation.record`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-record).


```ocaml
# Data.Validation.record ;;
- : ((string * Data.t) list -> 'a Data.Validation.validated_record) ->
    Data.t -> 'a Data.Validation.validated_value
= <fun>
```

Its signature is a bit different from those we have seen
previously. Indeed, the function takes as an argument another
function, which will be responsible for validating the fields of the
record:


```ocaml
# Data.Validation.record 
   (fun _ -> failwith "To be done")
   (Data.int 10) ;;
- : 'a Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "record"; given = Data.Int 10})
```

The function that must be passed as an argument is provided by the
list of fields extracted from the record. Then, we can use the
operators
[`let+`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(let+))
and
[`and+`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(and+))
to perform validations on each field of our record. This is called
**applicative validation**, which collects _all errors_. To analyze
the fields of a record, YOCaml provides three essential functions:


- [`required`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-required)
  for required fields
- [`optional`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-optional)
  for optional fields
- [`optional_or
  ~default`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-optional_or)
  for optional fields that provide a `default` value if the field does
  not exist


All three functions are called in the same way: `required fields key
validator`:

```ocaml
# Data.Validation.required ;;
- : (string * Data.t) list ->
    string ->
    (Data.t -> 'a Data.Validation.validated_value) ->
    'a Data.Validation.validated_record
= <fun>
```

- `fields` is the list of fields of the record (which is the argument
  passed to the function given to `record`)
- `key` is the field we want to observe
- `validator` is a validator (like those we have seen previously) used
  to validate the field.


### A first example

Let's imagine the following type:

```ocaml
type my_point = {
  label: string option
; x: int
; y: int
}
```

We could imagine the following validation function:

```ocaml
let validate_point data = 
  let open Yocaml.Data.Validation in 
  record (fun fields -> 
    let+ label = optional fields "label" string 
    and+ x = required fields "x" int 
    and+ y = required fields "y" int in 
    (* Here you can do whatever you want. *)
    { label; x; y} ) data
```

Since the `data` argument is simply passed to the `record` function,
we can even omit it:

```diff
- let validate_point data = 
+ let validate_point =
  let open Yocaml.Data.Validation in 
  record (fun fields -> 
    let+ label = optional fields "label" string 
    and+ x = required fields "x" int 
    and+ y = required fields "y" int in 
    (* Here you can do whatever you want. *)
-   { label; x; y} ) data
+   { label; x; y} )
```

We can verify that our validation function works correctly by trying
to validate multiple pieces of data (and observe that all errors are
properly captured):

When the value is not a record:

```ocaml
# validate_point Data.(string "a point") ;;
- : my_point Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "record";
    given = Data.String "a point"})
```

When all fields are missing:

```ocaml
# validate_point Data.(record []) ;;
- : my_point Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_record
   {Yocaml.Data.Validation.errors =
     Data.Validation.Missing_field {Yocaml.Data.Validation.field = "x"}
     Data.Validation.Missing_field {Yocaml.Data.Validation.field = "y"};
    given = []})
```

Since the `label` field is _optional_, it is normal that it is not
listed as a missing field.


```ocaml
# validate_point Data.(record [
    "x", int 10
  ; "y", int 23
  ; "label", string "my first point"
  ]) ;;
- : my_point Data.Validation.validated_value =
Ok {label = Some "my first point"; x = 10; y = 23}
```

Record validation is at the core of metadata validation in YOCaml, and
as we can see, it allows us to apply validation steps to each field of
a record to ensure that every field is independently valid before
constructing arbitrary data.

Just like with data projection, the ability to validate _records_
allows us to build more specific validators, such as for `sums`,
`pairs`, etc.


### Tuple validation

As we saw in projections, having record validation _unlocks_ the
possibility to describe more complex data types. For example:

- [`pair`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-pair)
  to logically validate pairs
- [`triple`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-triple)
  to logically validate triples
- [`quad`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-quad)
  unsurprisingly, to validate 4-element tuples

Their operation is identical to other validators. For example, to
construct a validator for triples of type `bool * int * string`:


```ocaml
# let my_triple_validator = 
     Data.Validation.(triple bool int string) ;;
val my_triple_validator :
  Data.t -> (bool * int * string) Data.Validation.validated_value = <fun>
```

Which we can directly test like this:


```ocaml
#  (true, 42, "Hello World")
   |> Data.(triple bool int string)
   |> my_triple_validator ;;
- : (bool * int * string) Data.Validation.validated_value =
Ok (true, 42, "Hello World")
```

The mechanism is, _once again_, dual to projection: **we validate a
record as a pair**, and we describe _triples_ as a _pair of pairs_,
etc.

### Sum Validation

As with _products_ (pairs, triples, etc.), we can use record
validation to describe the validation of sums. More generally, we can
use the
[`either`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-either)
validator:


```ocaml
# Data.Validation.either ;;
- : (Data.t -> 'a Data.Validation.validated_value) ->
    (Data.t -> 'b Data.Validation.validated_value) ->
    Data.t -> ('a, 'b) Either.t Data.Validation.validated_value
= <fun>
```

And just like with projections, there is a more generic validator,
[`sum`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-sum),
which allows enumerating validators for the constructors of an
arbitrary sum. For example:

```ocaml
# let my_either valid_left valid_right = 
    Data.Validation.sum [
      "left", valid_left
    ; "right", valid_right
    ] ;;
val my_either :
  (Data.t -> 'a Data.Validation.validated_value) ->
  (Data.t -> 'a Data.Validation.validated_value) ->
  Data.t -> 'a Data.Validation.validated_value = <fun>
```

#### Mapping

We can see that the type of `my_either` is noticeably different from
that of `either`. Indeed, `either` is a `('a, 'b) Either.t
Data.validable`, while `my_either` is a `'a Data.validable`. The two
validators provided to it **must return data of the same type**. To
obtain a validator of type `('a, 'b) Either.t Data.validable`, we want
to wrap the results of the two validators in `Left` and `Right`,
_respectively_.


This operation is called `map` and can be invoked using the infix
operator
[`$`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-($)). Its
type is `('a -> ('b, 'c) Result.t) -> ('b -> 'd) -> 'a -> ('d, 'c)
Result.t`, in other words: `v $ f` constructs a validator (i.e., a
function) that validates using `v` and, if the validation succeeds,
applies `f` to the validated result. We can therefore rewrite
`my_either` to have the same behavior as the `either` validator like
this:


```ocaml
# let my_either valid_left valid_right = 
    let open Yocaml.Data.Validation in
    sum [
      "left", valid_left $ (fun x -> Either.Left x)
    ; "right", valid_right $ (fun x -> Either.Right x)
    ] ;;
val my_either :
  (Data.t -> ('a, Data.Validation.value_error) result) ->
  (Data.t -> ('b, Data.Validation.value_error) result) ->
  Data.t -> ('a, 'b) Either.t Data.Validation.validated_value = <fun>
```
The module
[`Yocaml.Data.Validation`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#)
exposes several small utility operators like `$`, which we will see
later.

There are still many things to cover before we are done with
validation; however, we have seen enough to implement the _validation_
part of the two modules we looked at in the section dedicated to data
projection.


## A Real World Example

Let's go back to our two modules, `Gender` and `User`, and add the
_validation_ part. You’ll see, the YOCaml API should be intuitive.

### Gender Validation

As a reminder, here is how was our `Gender` module:


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

Now, we are going to add a `from_data` function, whose purpose will
logically be to validate a sum:


```diff
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
+
+  let from_data = 
+    let open Yocaml.Data.Validation in 
+    sum [
+      "male", null $ (fun () -> Male)
+    ; "female", null $ (fun () -> Female)
+    ; "other", string $ (fun g -> Other g)
+    ]
 end
```

As we can see, the validation function (`from_data`) is analogous to
the projection function (`to_data`).


<div class="hidden-toplevel">

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
    
  let from_data = 
    let open Yocaml.Data.Validation in 
    sum [
      "male", null $ (fun () -> Male)
    ; "female", null $ (fun () -> Female)
    ; "other", string $ (fun g -> Other g)
    ]
end
```

</div>

We can now test the validation _round-trip_:


```ocaml
# Gender.from_data (Gender.(to_data Female)) ;;
- : Gender.t Data.Validation.validated_value = Ok Gender.Female
```

```ocaml
# Gender.from_data (Gender.(to_data (Other "an other gender"))) ;;
- : Gender.t Data.Validation.validated_value =
Ok (Gender.Other "an other gender")
```

Now that we can validate _genders_, we can move on to validating a
_user_!


### User Validation

As a reminder, here is how was our `User` module:


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

As with the `Gender` module, we will add a `from_data` function, which
will need to validate a record. We saw the `into` function, which
allows using a module as a projection tool. There is also the
[`from`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-from)
function, which allows using a module to validate a field.

```diff
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
    
+  let rec from_data data = 
+    let open Yocaml.Data.Validation in 
+    record (fun fields -> 
+      let+ username = required fields "username" string 
+      and+ firstname = optional fields "firstname" string 
+      and+ lastname = optional fields "lastname" string 
+      and+ age = required fields "age" int 
+      and+ gender = 
+        required fields "gender" (from (module Gender))
+      and+ identities = 
+        optional fields "identities" (list_of from_data) in 
+      make username ?firstname ?lastname 
+           ~age ~gender ?identities
+    ) data
 end
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
    
  let rec from_data data = 
    let open Yocaml.Data.Validation in 
    record (fun fields -> 
      let+ username = required fields "username" string 
      and+ firstname = optional fields "firstname" string 
      and+ lastname = optional fields "lastname" string 
      and+ age = required fields "age" int 
      and+ gender = required fields "gender" (from (module Gender))
      and+ identities = optional fields "identities" (list_of from_data) in 
      make username ?firstname ?lastname ~age ~gender ?identities
    ) data
end

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

</div>

> Note a small subtlety: the `data` argument is passed rather than
> eliminated, essentially because the `from_data` function is
> **recursive**.

And just like with genders, we can attempt a _round-trip_ with `xvw2`,
which we created during the data projections tutorial:


```ocaml
# xvw2 |> User.to_data |> User.from_data ;;
- : User.t Data.Validation.validated_value =
Ok
 {User.username = "xvw2"; firstname = Some "Xavier";
  lastname = Some "Van de Woestyne"; age = 36; gender = Gender.Other "male";
  identities =
   [{User.username = "xvw"; firstname = None; lastname = None; age = 36;
     gender = Gender.Male; identities = []};
    {User.username = "xvw"; firstname = None; lastname = None; age = 36;
     gender = Gender.Male; identities = []}]}
```

At this point, we have the opportunity to explore how to build complex
validation schemas. However, a few minor frustrations become apparent!
Indeed, our examples so far seem to only allow validation of a limited
set of primitive types. For instance, how can we ensure that `age` is
**always positive**?


In the next section, we will see how to compose and build validators
to capture as many validation rules as possible.
