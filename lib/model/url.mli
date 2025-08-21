(** Represents URLs (resolvable). *)

(** {1 Dealing with URL} *)

(** The type describing a URL. *)
type t

(** Retreive the underlined computed URI. *)
val uri : t -> Uri.t

(** [resolve url path] change the path of an URL. *)
val resolve
  :  ?on_query:[ `Remove | `Keep | `Set of (string * string list) list ]
  -> t
  -> Yocaml.Path.t
  -> t

(** {1 YOCaml related stuff} *)

(** Validate an URL from a string representation. *)
val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value

(** Normalize an URL into the following. *)
val normalize : t -> Yocaml.Data.t
