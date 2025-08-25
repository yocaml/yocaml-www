(** A URL associated with a title and a potential description. *)

(** {1 Types} *)

type t

val make : ?name:string -> ?description:string -> Url.t -> t
val name : t -> string
val url : t -> Url.t
val description : t -> string option
val compare : t -> t -> int

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t
