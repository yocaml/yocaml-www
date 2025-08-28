(** The Resolver allows you to resolve different paths (whether they
    are paths from the source, target, etc.).

    It is generally transmitted almost everywhere and functions as a
    module whose configuration is defined when the generator is
    executed. *)

(** {1 Types} *)

(** The resolver, passed from function to function. It contains all
    the data needed to resolve any target and locate any source. *)
type t

(** Initialise a resolver.
    - [cache_folder] describes the directory
      where the cache will be stored, by default: [./_cache]
    - [source_folder] describes the directory
      where source are stored, by default: [./]
    - [target_folder] describes the folder where the site will
      be generated, by default: [./_www]
    - [server_root] describe the subfolder where the website
      is served, by default: [/]

    The real target is computed by [target_folder / server_root] in order
    to manage generation into subdirectories. *)
val make
  :  ?cache_folder:Yocaml.Path.t
  -> ?source_folder:Yocaml.Path.t
  -> ?target_folder:Yocaml.Path.t
  -> ?server_root:Yocaml.Path.t
  -> unit
  -> t

val binary : Yocaml.Path.t

(** {1 Source}

    Resolver dedicated to resolving source element (raw content). *)

module Source : sig
  (** All sources elements. *)

  val configuration : t -> Yocaml.Path.t
  val assets : t -> Yocaml.Path.t
  val images : t -> Yocaml.Path.t
  val css : t -> Yocaml.Path.t
  val css_file : t -> string -> Yocaml.Path.t
  val fonts : t -> Yocaml.Path.t
  val template : t -> string -> Yocaml.Path.t
  val tutorial : t -> Yocaml.Path.t
end

(** {1 Cache}

    Resolver dedicated to resolving cache elements *)

module Cache : sig
  (** The cache stores various elements that are useful for generating
      pages and intermediate states. *)

  (** Returns the path where the cache dedicated to YOCaml is located. *)
  val global : t -> Yocaml.Path.t

  module Sidebar : sig
    val tutorial : t -> Yocaml.Path.t
  end
end

(** {1 Target}

    Resolver dedicated to resolving target. *)

module Target : sig
  (** All targets describe paths in which files are potentially
      created. *)

  val assets : t -> Yocaml.Path.t
  val css_file : t -> Yocaml.Path.t
  val tutorial : t -> source:Yocaml.Path.t -> Yocaml.Path.t
  val fonts : t -> Yocaml.Path.t
  val images : t -> Yocaml.Path.t
end

(** {1 Server}

    Resolver dedicated to resolving target from the root of the
    server. *)

module Server : sig
  (** Resolve path from a server perspective. i.e: [_www/home/index]
      is [/www/home/index]. *)

  (** Converts a path from the target as if it were served by the
      server. For example: [_www/foo/index.html] becomes
      [/foo/index.html]. *)
  val from_target : t -> Yocaml.Path.t -> Yocaml.Path.t
end
