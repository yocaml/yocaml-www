---
title: Moving images
description: "A First Action: Moving Images to the Target"
synopsis: 
  With our skeleton in place, we can now create our first action. 
  We’ll start by simply moving some of the _assets_, the images, 
  to the target directory, `_www`.
date: 2025-09-03
updates:
  - key: 2025-09-03
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>"]
---

<div class="hidden-toplevel">

```ocaml
# #install_printer Yocaml.Path.pp ;;
# #install_printer Yocaml.Deps.pp ;;
```

```ocaml
open Yocaml
let www = Path.rel [ "_www" ] ;;
```

</div>

To start, download the file [icons.svg](/assets/images/icons.svg) into
your `assets/images` directory. It contains several SVG icons (the
OCaml logo, the [Creative Commons](https://creativecommons.org/) logo,
and an RSS/Atom logo) sourced from [Simple
Icons](https://simpleicons.org/).

> The SVG file merges multiple symbols, making it easy to invoke icons
> using the
> [`<use>`](https://developer.mozilla.org/en-US/docs/Web/SVG/Reference/Element/use)
> tag. This allows you to include an external SVG while keeping the
> ability to style it with CSS (which is not possible with the `<img>`
> tag). The `icons` file may not be directly viewable in your browser,
> but rest assured, it is the file used for this site.


## Copying a File

YOCaml provides a predefined action to simply copy a file into a given
directory:

```ocaml
# Action.copy_file ;;
- : ?new_name:string -> into:Path.t -> Path.t -> Action.t = <fun>
```

First, we’ll create an action that can copy a single file. Later,
we’ll see how to _batch_ this action. We also create variables to help
us more easily qualify the paths we’ll be using:

```ocaml
let assets = Path.rel [ "assets" ]
let images = Path.(assets / "images")

let copy_image image_path = 
  let images_path = Path.(www / "images") in
  Action.copy_file ~into:images_path image_path
```

We can now modify our `program` function to copy our `icons.svg` file
by chaining the action we just created:


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
+  >>= copy_image Path.(images / "icons.svg")
   >>= Action.store_cache cache
```

If we run our program using the command `dune exec bin/blog.exe`, the
standard output should display the following logs:


```shell
[DEBUG]Cache restored from `./_www/.cache`
[DEBUG]`./_www/images/icons.svg` will be written
[INFO]`./_www/images/icons.svg` has been written
[DEBUG]Cache stored in `./_www/.cache`
```

If we immediately run the command again, the output should indicate
that the `icons.svg` file is already up to date, ensuring that
**minimality has been respected**:


```shell
[DEBUG]Cache restored from `./_www/.cache`
[DEBUG]`./_www/images/icons.svg` is already up-to-date
[DEBUG]Cache stored in `./_www/.cache`
```

You can verify that everything works by modifying the source file or
deleting the target to ensure that the file is only copied when
necessary.

However, specifying each potential image manually is a bit tedious. We
would like to apply this action to all images in the `assets/images`
directory.

## Batching Multiple Actions

The
[Batch](https://yocaml.github.io/doc/yocaml/yocaml/Yocaml/Batch/index.html)
module provides various functions to collapse a series of actions into
a single one. Let’s focus on the following function:

```ocaml
# Yocaml.Batch.iter_files ;;
- : ?where:(Path.t -> bool) -> Path.t -> (Path.t -> Action.t) -> Action.t =
<fun>
```

This function will **produce an action** that goes through all files
in a directory (referenced by a path, as always) that satisfy the
`where` predicate (if provided; otherwise, all child files are
considered valid) and **applies an action to them**. The function
itself is an action.

What we want to do is go through all the images in the `assets/images`
directory and apply our `copy_image` function, which is exactly of
type `Path.t -> Action.t` — _perfect!_


```ocaml
let copy_images =
  Batch.iter_files
    ~where:(fun file ->
      Path.has_extension "svg" file
      || Path.has_extension "png" file
      || Path.has_extension "jpg" file
      || Path.has_extension "gif" file)
    images copy_image
```

If we inspect the type of `copy_images`, we can see that the function
has the type `Action.t`. We can therefore modify `program` (and add
more images to `assets/images` to verify that everything works):


```diff
 let program () =
   let open Eff in
   let cache = Path.(www / ".cache") in
   Action.restore_cache cache
-  >>= copy_image
+  >>= copy_images
   >>= Action.store_cache cache
```

We have designed our first action, which simply moves files from a
directory (only when necessary) while respecting a certain
predicate. Before moving on, we can make a few minor adjustments!


## Minor Improvements

Even though the code we wrote is perfectly valid, there are at least
two possible improvements. First, one might question the need to
separate the `copy_image` and `copy_images` actions. Indeed,
`copy_image` is essentially an _alias_ for `copy_file`, so we could
rewrite `copy_images` as follows:


```ocaml
let copy_images =
  let images_path = Path.(www / "images") in
  Batch.iter_files
    ~where:(fun file ->
      Path.has_extension "svg" file
      || Path.has_extension "png" file
      || Path.has_extension "jpg" file
      || Path.has_extension "gif" file)
    images
    (Action.copy_file ~into:images_path)
```

### A Utility Function

The second possible improvement concerns the way we check whether a
path is an image. The code is quite redundant, and we might want to
handle other files with multiple possible extensions (notably
fonts). We could write a helper function that verifies whether a file
has one of the extensions provided in a list:

```ocaml
let with_ext exts file =
  List.exists  (fun ext -> Path.has_extension ext file) exts
```

This allows us to rewrite our `copy_images` action in a more concise
way (without losing readability):


```ocaml
let copy_images =
  let images_path = Path.(www / "images")
  and where = with_ext [ "svg"; "png"; "jpg"; "gif" ] in
  Batch.iter_files 
    ~where images 
    (Action.copy_file ~into:images_path)
```

And there you have it! We’ve coded our **very first action** and laid
the groundwork for a static site generator! _Awesome_.

## Conclusion

In this article, we reviewed how to use actions and batches of actions
for very simple tasks. Implicitly, we also saw how well actions
compose and how partial application can handle the cache so that, in
the end, you can chain actions together in the main program.

In the next part, we’ll learn how to create files with YOCaml.

