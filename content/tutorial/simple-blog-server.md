---
title: A development server
description: 
  Setting up a small development server to facilitate page writing
synopsis: 
  Now that we have some pages, let’s see how to set up a small 
  development server to preview our generated site in action!
date: 2025-09-08
updates:
  - key: 2025-09-08
    value:
      description: "First version"
      authors: ["grm <grimfw@gmail.com>", "xvw <xaviervdw@gmail.com>"]
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

Up to now, we’ve been using `cat` each time to check that our
generator was working properly. That wasn’t a very efficient
approach—especially if we want to fine-tune our _layout_. Being able
to view the site in a real environment is a huge advantage! You might
think that since our generator produces HTML pages (among other
things), we could simply open them directly in a web
browser. Unfortunately, that doesn’t really work. When creating our
templates, we assumed that the site would always be served from the
root of a server—but chances are you’re not generating your site at
the root of your computer’s filesystem, right?

To address this, the runtimes (`Yocaml_unix` and `Yocaml_eio`) come
with a function similar to `run`, whose purpose is to start a small
local server that serves our files:

## Starting the Server

The function is very similar to its counterpart, `run`. Let’s take a
quick look at its specification:


```ocaml
# Yocaml_unix.serve ;;
- : ?level:Yocaml_runtime.Log.level ->
    ?custom_error_handler:(Format.formatter ->
                           Yocaml.Data.Validation.custom_error -> unit) ->
    target:Path.t -> port:int -> (unit -> unit Eff.t) -> unit
= <fun>
```

The function is very similar. Just like `run`, it also takes a log
level, and the function `(unit -> unit Yocaml.Eff.t)` is the same as
the one accepted by `run`. In fact, the only differences are in
`target` and `port`.

- `target` is the directory that will serve as the root of our
  server. Here, we’ll set it to the `_www` directory.

- `port` is the port our server will listen on. For this example,
  we’ll use `8000`.


### Serving our Site

In practice, we can simply adjust how we run our generator like this:


```diff
let () = 
-  Yocaml_unix.run ~level:`Debug program
+  Yocaml_unix.serve 
+       ~level:`Info 
+       ~target:www ~port:8000 
+       program
```

If you run your generator (`dune exec bin/blog.exe`), you should see
the following message appear in your terminal:


```shell
[INFO]Launching server <http://localhost:8000>
```

And by visiting [localhost:8000](http://localhost:8000), you should be
able to see your website! _Excellent_.


#### Server Features

The server is **essentially a development server**—it is **not
intended for production use**. In fact, every time the server receives
a request, it **re-runs the program**.


> The fact that the program is re-executed on **every** page refresh
> might sound alarming. However, remember that YOCaml strives for
> minimalism: if nothing has changed, refreshing a page will result in
> no modifications at all.

Additionally, the server provides a minimal browser view (if the
directory does not contain an `index.html` page) and allows serving a
`/404.html` page as a substitute for 404 errors.


## Conditional Execution

Our initial approach is a bit crude. Ideally, we want to control via
CLI arguments whether we want to build our site (for example, to be
invoked from CI) or serve it during the drafting process.

We can use a very simple approach, which is sufficient for the
purposes of this tutorial:


<!-- $MDX skip -->
```ocaml

let () =
  match Sys.argv.(1) with
  | "server" -> 
    Yocaml_unix.serve 
       ~level:`Info 
       ~target:www 
       ~port:8000 
       program
  | _ | (exception _) -> 
     Yocaml_unix.run 
       ~level:`Debug 
       program

```

Of course, it’s possible to drastically improve our CLI by using tools
like [Cmdliner](https://github.com/dbuenzli/cmdliner) to, for
instance, make the `port` configurable. (You can find resources for
[command-line parsing](https://ocaml.org/docs/cli-arguments) on the
official site.)


## Conclusion

We’ve seen how to support a small development server, which is very
useful during the drafting or _design_ process. It has been designed
to be easy to use and flexible enough to cover a wide range of
scenarios.

