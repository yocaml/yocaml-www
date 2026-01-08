---
title: Fine-grained validators
description: Building more accurate validators
synopsis: 
  Now that we have seen how to build validators that make it possible
  to validate _the shape_ of data described by the `Data` module, it is time
  to look at how to build more fine-grained validators, capable
  of validating concrete data.
date: 2025-12-25
updates:
  - key: 2025-12-25
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

Indeed, [in the previous section](/tutorial/metadata-validation.html),
we simply made sure that data of type `Data.t` **respected a certain
shape**.  Even though this is a good start, it is not enough to
effectively (and _safely_) describe precise validation schemas. In
this section, we will focus on the **constructing validators**.


## Sequencing and composing validations

During the [first part](/tutorial/metadata-validation.html) of this
tutorial, we mainly worked with [`'a
validable`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/index.html#type-validable),
that is, validators that consume values of type `Yocaml.Data.t`. Since
YOCaml generally takes care of converting arbitrary data (JSON, TOML,
YAML, etc.) into `Data.t`, the first step usually consists of
*validating the shape*, and the combinators we previously saw **are
largely sufficient** for that. However, once our data has been
transformed into regular OCaml values, we would like to apply
additional validation steps.  For example, as we saw in the `User`
example, we might want to ensure that ages are strictly positive
integers.

In other words, we would like to be able to *pipe* the result of a
first validator into a second validator. To do this, YOCaml provides
several concise operators to **compose validators**.


### Applying arbitrary functions

As we saw earlier, it is possible to apply *regular* functions when a
validator succeeds using the
[`$`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-($))
operator. For example, we could define a validator that validates an
integer number and adds `1` to it using the
[`succ`](https://ocaml.org/manual/5.4/api/Stdlib.html#VALsucc)
function:


```ocaml
let int_plus_1 = 
  let open Data.Validation in
  (int $ succ)
```

```ocaml
# int_plus_1 (Data.int 42) ;;
- : (int, Data.Validation.value_error) result = Result.Ok 43
```

Since the set of primitive metadata types in YOCaml is fairly limited
(`string`, `bool`, `int`, and `float`), `$` is generally used to give
**more meaning** to our data. Another example would be using a
`string` to represent `int64` values, for instance:


```ocaml
let int64 = 
  let open Data.Validation in 
  (string ~strict:false $ Int64.of_string)
```

```ocaml
# int64 (Data.string "1234567890234567890") ;;
- : (int64, Data.Validation.value_error) result =
Result.Ok 1234567890234567890L
```

### Piping validators

The
[`&`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(&))
operator is very similar to `$` except that it **sequences two
validators**: `v1 & v2` produces a validator that first validates with
`v1`, and if this validation succeeds, passes its result to validator
`v2`. To better observe the behavior of `&`, YOCaml provides specific
validator modules:

- [`Yocaml.Data.Validation.Int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html)
  which contains integer-specific validators
- [`Yocaml.Data.Validation.Float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Float/index.html)
  which contains float-specific validators
- [`Yocaml.Data.Validation.String`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/String/index.html)
  which contains string-specific validators

**Be careful**, the validators provided in these modules validate
`int`, `float`, and `string` values respectively, not values of type
`Data.t`, so they can only be used after the `int`, `string`, and
`float` validators. For example, we could describe a validator for
positive integers:


```ocaml
let positive_int = 
  let open Data.Validation in 
  (int & Int.positive)
```

```ocaml
# positive_int (Data.int 42) ;;
- : (int, Data.Validation.value_error) result = Result.Ok 42
```

```ocaml
# positive_int (Data.int (-42)) ;;
- : (int, Data.Validation.value_error) result =
Result.Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "-42"; message = "should be positive"})
```

I encourage you to take a look at the three modules
([`Yocaml.Data.Validation.Int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html),
[`Yocaml.Data.Validation.Float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Float/index.html)
and
[`Yocaml.Data.Validation.String`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/String/index.html))
to discover the various specific validators they provide.

As long as the types are compatible, several validators can be freely
sequenced. For example, by using
[`lt`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-lt)
and
[`gt`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-gt)
we can describe a `bound` validator:


```ocaml
let bound ~min ~max = 
  let open Yocaml.Data.Validation in 
  int & Int.gt min & Int.lt max
```

Here we pass a valid value, greater than `12` and less than `14`:

```ocaml
# bound ~min:12 ~max:14 (Data.int 13) ;;
- : (int, Data.Validation.value_error) result = Result.Ok 13
```

Here we pass an invalid value, `>= 14`:

```ocaml
# bound ~min:12 ~max:14 (Data.int 42) ;;
- : (int, Data.Validation.value_error) result =
Result.Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "42";
    message = "should be lesser than 14"})
```

However, this validator is only meant to illustrate sequencing
multiple validators because
[`bounded`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-bounded)
already exists in `Int` and `Float`.


### Rewriting the User example

Now that we have seen how to sequence validators, we can improve the
validation of our `User.t` using more appropriate combinators! Indeed,
we were previously only checking that the data _had the correct
shape_; now, we can add additional validations.

First, we will create a validator to ensure that a string is not
empty:


```ocaml
let not_blank = 
  let open Yocaml.Data.Validation in 
  string & String.not_blank
```

No special magic here; we simply ensure that the data we are
validating is indeed a string and then pass the validated string to
the
[`String.not_blank`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/String/index.html#val-not_blank)
validator.

We can also add a validator to validate the age:


```ocaml
let seems_legit_age = 
  let open Yocaml.Data.Validation in 
  int & Int.ge 4
```

And yes, we assume that under 4 years old, it’s too early to go online
(maybe a bit of an _over-the-top hot take_) using the
[`ge`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-ge)
validator.

We can now rewrite our validation function!


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
      let+ username = required fields "username" not_blank
      and+ firstname = optional fields "firstname" not_blank
      and+ lastname = optional fields "lastname" not_blank
      and+ age = required fields "age" seems_legit_age 
      and+ gender = required fields "gender" (from (module Gender))
      and+ identities = optional fields "identities" (list_of from_data) in 
      make username ?firstname ?lastname
          ~age ~gender ?identities
    ) data
end
```

</div>


```diff
 module User = struct 
  
  (* ... *)
    
+  let rec from_data data = 
+    let open Yocaml.Data.Validation in 
+    record (fun fields -> 
+      let+ username = required fields "username" not_blank
+      and+ firstname = optional fields "firstname" not_blank
+      and+ lastname = optional fields "lastname" not_blank
+      and+ age = required fields "age" seems_legit_age 
+      and+ gender = 
+        required fields "gender" (from (module Gender))
+      and+ identities = 
+        optional fields "identities" (list_of from_data) in 
+      make username ?firstname ?lastname
+          ~age ~gender ?identities
+    ) data
end
```

The use of infix operators is justified by the fact that, generally,
we pass validators constructed on the fly directly as the last
arguments to `required` and `optional`.



### Validator alternative

Sometimes, there are multiple ways to validate a piece of data. For
example, we could imagine the following type:


```ocaml
type human = {
  display_name: string
; first_name: string option 
; last_name: string option
}
```

The _trivial_ validator for this kind of data would be the following:


```ocaml
let validate_from_record = 
  let open Yocaml.Data.Validation in 
  record (fun fields -> 
    let+ display_name = required fields "display_name" not_blank
    and+ first_name = optional fields "first_name" not_blank 
    and+ last_name = optional fields "last_name" not_blank in 
    { display_name; first_name; last_name}
  )
```

However, since the `last_name` and `first_name` fields are optional,
we could imagine that a simple `string` (representing the
`display_name` field) would be sufficient. For example, a validator of
this form:


```ocaml
let validate_from_string = 
  let open Yocaml.Data.Validation in 
  string $ (fun display_name ->  { 
     display_name
   ; first_name = None 
   ; last_name = None } )
```

The YOCaml validation API provides a
[`/`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(/))
operator (an alternative operator) where `v1 / v2` can be read as
“validate with `v2` if validation `v1` fails.” This makes it a perfect
operator **for validating from different representations**.

In our example, we can _branch_ our two validators in this way:


```ocaml
let validate_human = 
  let open Yocaml.Data.Validation in 
  validate_from_record / validate_from_string
```

This has the effect of creating a validator **accepting records**:

```ocaml
# validate_human 
    Data.(record ["display_name", string "Xavier"]) ;;
- : (human, Data.Validation.value_error) result =
Result.Ok {display_name = "Xavier"; first_name = None; last_name = None}
```

But **also accepting strings**:

```ocaml
# validate_human Data.(string "Xavier") ;;
- : (human, Data.Validation.value_error) result =
Result.Ok {display_name = "Xavier"; first_name = None; last_name = None}
```

#### Const validator

Validator alternatives explicitly allow multiple paths to validate
data and, when coupled with the
[`const`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-const)
validator, allow **handling default cases** (_neutral
elements_). `const` is a validator that **always succeeds**. So
combining it with sequences of alternatives enables a **default
handling**. For example:


```ocaml
let validate_human = 
  let open Yocaml.Data.Validation in 
  validate_from_record 
  / validate_from_string 
  / const { display_name = "Unknown"
          ; first_name = None
          ; last_name = None }
```

If I pass legitimate data, the correct validator is executed:

```ocaml
# validate_human Data.(string "Xavier") ;;
- : (human, Data.Validation.value_error) result =
Result.Ok {display_name = "Xavier"; first_name = None; last_name = None}
```

But if I try to validate data that satisfies neither
`validate_from_string` nor `validate_from_record`, `const` will serve
as the _fallback_:


```ocaml
# validate_human Data.null ;;
- : (human, Data.Validation.value_error) result =
Result.Ok {display_name = "Unknown"; first_name = None; last_name = None}
```

### Reuse and precondition

We have seen that we can arbitrarily compose validators, map
functions, but sometimes we may want to enrich existing validators.

Let us imagine, for example, that we describe an article as being a
_normal page_ endowed with additional fields: `publication_date` and
`tags`:


<div class="hidden-toplevel">

```ocaml
module Page = struct 
  type t = {
    title: string 
  ; desc: string option 
  }
  
  let normalize {title; desc} = 
    let open Yocaml.Data in [
      "title", string title
    ; "desc", option string desc
    ]
    
  let validate = 
    let open Yocaml.Data.Validation in 
    record (fun fields -> 
      let+ title = required fields "title" string 
      and+ desc = optional fields "desc" string 
      in { title; desc } )
end
```

</div>

```ocaml
type article = { 
  page: Page.t
; publication_date: Yocaml.Datetime.t
; tags: string list
}
```

A _naïve_ way to validate an article would be to consider that a page
is **a field of an article**, in this way:


```ocaml
let validate_article = 
  let open Yocaml.Data.Validation in
  record (fun fields -> 
    let+ page = required fields "page" Page.validate 
    and+ publication_date = 
      required fields "date" Yocaml.Datetime.from_data
    and+ tags = 
      optional_or ~default:[] fields "tags" (list_of string)
    in { page; publication_date; tags })
```

However, even though this approach works, it is very frustrating
because it forces us to _nest_ the representation of a
page. Fortunately, we have two approaches to avoid this _nesting_.


#### Holding a precondition

We used
[`let+`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(let+))
and
[`and+`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(and+))
to validate record fragments. These are operators (respectively
**map** and **product** (or **zip**)) that describe _applicative_
validation
[pipelines](https://en.wikipedia.org/wiki/Applicative_functor). The
specificity of applicative validation is that **it collects all
errors**. However, the YOCaml data validation API exposes an operator:
[`let*`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-(let*))
which allows one to pre-apply a validation:


```ocaml
let validate_article data = 
  let open Yocaml.Data.Validation in
  let* page = Page.validate data in
  record (fun fields -> 
    let+ publication_date = 
      required fields "date" Yocaml.Datetime.from_data
    and+ tags = 
      optional_or ~default:[] fields "tags" (list_of string)
    in { page; publication_date; tags }) data
```

This looks very similar to the use of `&`, except that we have more
control over the `data` variable, which we can reuse. Indeed, if we
had wanted to use `&`, we would have had to _twist_ the API a bit to
return, in addition to `page`, the `data` argument.

However, this approach may be unsatisfying because we do not use
`page` in the body of the validation of the record fields. Ideally, we
would like to restrict the use of `let*` to cases where we want to use
the result of the first validation in the body of a subsequent
validation. Which is not the case here.


#### Prism of a record

Another approach, _more appropriate_ in our example, is to use
[`sub_record`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-sub_record),
a function similar to `required` and `optional` that allows using the
fields of a record to validate a `subrecord`. For example, by applying
it to our example:


```ocaml
let validate_article = 
  let open Yocaml.Data.Validation in
  record (fun fields -> 
    let+ page = sub_record fields Page.validate
    and+ publication_date = 
      required fields "date" Yocaml.Datetime.from_data
    and+ tags = 
      optional_or ~default:[] fields "tags" (list_of string)
    in { page; publication_date; tags })
```

Concretely, the `sub_record` function will **reconstruct** a record
from the `fields`, making it possible to apply **an arbitrary record
validator** to a list of fields.


#### Between preconditions and prisms

Preconditions and prism-like validations may seem quite similar;
however, in the example, we appeared to _argue_ that using
`sub_record` was more appropriate. How should one make a choice?

- When you want to **add members** to an existing model, you should
  prefer `sub_record`.

- When you want to use the result of a previous validation. Indeed,
  classic validations built with `let+` and `and+` are parallel
  validations: the intermediate validated members (record fields)
  cannot depend on each other. As soon as such inter-dependencies are
  required, you will use `let*` (while giving up the collection of
  **all errors**).

In practice, one should try to use `sub_record` as much as possible,
whenever feasible. It is also worth noting that the validation API is
_relatively flexible_, and therefore allows for alternative
approaches.

At this stage, we have **many tools to validate arbitrary data**, and
we are not far from being able to transform almost any value of type
`Data.t` into OCaml values that we fully control. There remains one
final point to cover: _how to create our own validators_?


## Creating our own validators

Now that we have seen how to **build on top of existing components**,
it is time to look at how to build **our own validators**. There are
three ways to construct a validator:

- By using a predicate (a function `'a -> bool`).
- By projecting to an option.
- By manually constructing a function.

Each approach has its own advantages. Indeed, building a predicate
**is compact and easy to use on the fly**, while the last approach
requires a bit more ceremony but **offers more control**.


### Using a predicate

The function
[`Yocaml.Data.Validation.where`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-where)
provides a simple way to turn a predicate (a function `'a -> bool`)
into a validator:


```ocaml
# Data.Validation.where ;;
- : ?pp:(Format.formatter -> 'a -> unit) ->
    ?message:('a -> string) ->
    ('a -> bool) -> 'a -> 'a Data.Validation.validated_value
= <fun>
```

The optional parameters `pp` and `message` **allow you to finely
construct the error message**. Indeed, if these parameters are not
provided, the error may be potentially cryptic.

For example, imagine a function that only validates even numbers:


```ocaml
let is_even = 
  let open Yocaml.Data.Validation in
  int & where (fun x -> Stdlib.Int.equal 0 (x mod 2))
```

Note that we **fully qualify the `Stdlib.Int` module** because opening
`Yocaml.Data.Validation` _shadows_ the `Int` module. We can now test
our validator in the _happy path_:


```ocaml
# is_even (Data.int 12) ;;
- : (int, Data.Validation.value_error) result = Result.Ok 12
```

And in a case where the validator is supposed to fail:

```ocaml
# is_even (Data.int 13) ;;
- : (int, Data.Validation.value_error) result =
Result.Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "*"; message = "unsatisfied predicate"})
```

Even if we get the expected result, we might be quite annoyed by the
**drastically unclear** message. Let's try to improve this by
rewriting our `is_even` function to add more context, using the two
optional parameters:


```ocaml
let is_even = 
  let open Yocaml.Data.Validation in
  int & where ~pp:Format.pp_print_int
              ~message:(fun _ -> "is not even")
              (fun x -> Stdlib.Int.equal 0 (x mod 2))
```

We use the function
[`pp_print_int`](https://ocaml.org/manual/5.2/api/Format.html#VALpp_print_int),
whose role is to _pretty-print_ numbers, and we specify the
message. We can now retry a case where the validator should fail:

```ocaml
# is_even (Data.int 13) ;;
- : (int, Data.Validation.value_error) result =
Result.Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "13"; message = "is not even"})
```

That's much better! The `where` function has its alternatives in the
modules
[`Yocaml.Data.Validation.String`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/String/index.html#val-where),
[`Yocaml.Data.Validation.Int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-where),
and
[`Yocaml.Data.Validation.Float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Float/index.html#val-where),
where the _pretty-printer_ (`pp`) obviously no longer needs to be
provided, but the `message` remains configurable. This allows us to
rewrite our `is_even` function as follows:



```ocaml
let is_even = 
  let open Yocaml.Data.Validation in
  int & where ~message:(fun _ -> "is not even")
              (fun x -> Stdlib.Int.equal 0 (x mod 2))
```

However, in some contexts, `where` can be a bit limited. Indeed,
sometimes we might want to be able to alter the return type of our
validator. In the next section, we will see how to project to an
option to create more flexible validations!



### Using option

There is a function analogous to `where`,
[`where_opt`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Float/index.html#val-where_opt),
which, instead of using a predicate, uses a function of type `'a -> 'b
option`, **providing more control over the return type of our
validator**:


```ocaml
# Data.Validation.where_opt ;;
- : ?pp:(Format.formatter -> 'a -> unit) ->
    ?message:('a -> string) ->
    ('a -> 'b option) -> 'a -> 'b Data.Validation.validated_value
= <fun>
```

As with `where`, `where_opt` has specialized counterparts in the
modules
[`Yocaml.Data.Validation.String`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/String/index.html#val-where),
[`Yocaml.Data.Validation.Int`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Int/index.html#val-where),
and
[`Yocaml.Data.Validation.Float`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/Float/index.html#val-where).

It is used in a manner very similar to `where`. For example, here is a
somewhat exotic validator that allows us to transform strings into the
polymorphic variants `Foo` or `Bar`:


```ocaml
let exotic_validator = 
  let open Yocaml.Data.Validation in 
  string & String.where_opt 
             ~message:(fun _ -> "not foo or bar")
             (function 
              | "foo" -> Some (`Foo)
              | "bar" -> Some (`Bar 10)
              | _ -> None)
```

Let's test it with valid strings, for example `foo`:

```ocaml
# exotic_validator Data.(string "foo") ;;
- : ([> `Bar of int | `Foo ], Data.Validation.value_error) result =
Result.Ok `Foo
```

We can try it with `bar` to confirm that the validator works
correctly!


```ocaml
# exotic_validator Data.(string "bar") ;;
- : ([> `Bar of int | `Foo ], Data.Validation.value_error) result =
Result.Ok (`Bar 10)
```

Now let's try it with an invalid string:

```ocaml
# exotic_validator Data.(string "other thing") ;;
- : ([> `Bar of int | `Foo ], Data.Validation.value_error) result =
Result.Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "other thing"; message = "not foo or bar"})
```

Perfect, as we can see, `where_opt` is much more flexible than `where`
because it allows us to deconstruct our value and control its
return. We could go further by **observing a value of type `Data.t`
directly**; for example, we could implement our own `pair` function
like this:


```ocaml
let my_pair a b = 
  let open Yocaml.Data.Validation in
  where_opt ~pp:Yocaml.Data.pp
            ~message:(fun _ -> "Pair expected")
            (function 
             | Yocaml.Data.List [a; b] -> 
                 (* If we have a list with two elements, 
                    we convert it into a pair. *)
                 Some (Yocaml.Data.record [
                   "fst", a
                 ; "snd", b
                 ])
             | (Record _) as x -> 
                 (* It is a record, so it is maybe a tuple! *)
                 Some x 
             | _ -> 
                 (* Not a list or a record, let's stop *)
                 None
            )
  & pair a b (* Let's run the regular validator *)
```

The idea is to accept lists as input for the `pair` validator (of
course, it could also be written using `/` and some _mapping_). If the
term we observe is a list of two elements, we construct a record; if
it is already a record, we return it; otherwise, we fail.

If I use my validator with a valid two-element list, the validation
succeeds:


```ocaml
# my_pair 
    Data.Validation.int 
    Data.Validation.string 
    Data.(list [int 1; string "2"]) ;;
- : (int * string, Data.Validation.value_error) result = Result.Ok (1, "2")
```

On the other hand, using the same expression, the default `pair`
validator fails:


```ocaml
# Data.Validation.pair 
    Data.Validation.int 
    Data.Validation.string 
    Data.(list [int 1; string "2"]) ;;
- : (int * string) Data.Validation.validated_value =
Error
 (Data.Validation.Invalid_shape
   {Yocaml.Data.Validation.expected = "pair";
    given = Data.List [Data.Int 1; Data.String "2"]})
```

**As an exercise**, I invite you to try rewriting the `my_pair`
validator using a formulation based on `/` and `$` to make sure you
are comfortable with validations!

Now that we have seen the two predicate-based methods, it is time to
look at the last way to build a custom validator!


### Using a dedicated function

A validator is nothing more than a function of type `'a -> 'b
validated_value`, where `'b validated_value` is a `('b, value_error)
result`. We can therefore very easily write a validation function
manually:


```ocaml
let my_dummy_validator x = Ok x
```

However, this validator is not very useful; in fact, it is _somewhat
of an identity validator_, which simply validates the data it
receives. To create truly useful validators, we want to be able to
produce errors. For this, we can use the function
[`Yocaml.Data.Validation.fail_with`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#val-fail_with):


```ocaml
# Data.Validation.fail_with ;;
- : given:string -> string -> 'a Data.Validation.validated_value = <fun>
```

The `given` argument is a textual representation of the data we are
trying to validate, and the second argument is the error message to
produce. For example, consider the following _very strange_ validator:


```ocaml
let validate_10 = function
  | 10 -> Ok 10 
  | x -> 
    let open Yocaml.Data.Validation in
    let given = string_of_int x in 
    fail_with ~given "I only accept 10!"
```

Yes, indeed, this is a validator that only accepts integers with the
value `10`, not very useful (and easily replaceable by
`Yocaml.Data.Validation.Int.equal 10`), but it highlights how to
construct a validator using `fail_with` to produce an error!


```ocaml
# validate_10 10 ;;
- : int Data.Validation.validated_value = Ok 10


# validate_10 11 ;;
- : int Data.Validation.validated_value =
Error
 (Data.Validation.With_message
   {Yocaml.Data.Validation.given = "11"; message = "I only accept 10!"})
```

Building a custom validator is therefore **nothing more than writing a
function that returns a `result` value**.


## Conclusion

We have seen how to compose and build increasingly refined
validators. However, there are other pre-built validators that you can
find in the module
[`Yocaml.Data.Validation`](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Data/Validation/index.html#),
which I encourage you to explore! Now that we are able to construct
validators that capture OCaml values as precisely as possible, we will
look at one final example to put into practice everything we have
learned for building **our own archetypes** (making documents readable
and injectable).

