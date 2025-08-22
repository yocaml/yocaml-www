(** Represents URLs (resolvable). *)

(** {1 Dealing with URL} *)

(** The type describing a URL. *)
type t

(** Retreive the underlined computed URI. *)
val uri : t -> Uri.t

(** Return the host of the URL. *)
val host : t -> string

(** Return an URL as string that suit for name.*)
val as_name : ?with_scheme:bool -> ?with_path:bool -> t -> string

(** Apply a function on the path. *)
val on_path : (Yocaml.Path.t -> Yocaml.Path.t) -> t -> t

(** [resolve url path] change the path of an URL. *)
val resolve
  :  ?on_query:[ `Remove | `Keep | `Set of (string * string list) list ]
  -> Yocaml.Path.t
  -> t
  -> t

val to_string : t -> string
val of_string : string -> t
val http : ?path:Yocaml.Path.t -> string -> t
val https : ?path:Yocaml.Path.t -> string -> t
val file : ?path:Yocaml.Path.t -> string -> t

(** {1 YOCaml related stuff} *)

(** Validate an URL from a string representation. *)
val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value

(** Normalize an URL into the following. *)
val normalize : t -> Yocaml.Data.t
