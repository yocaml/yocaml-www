(** Describes a tag/keyword. *)

type t

val make : string -> t
val to_string : t -> string

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t

val of_list : string list -> Set.t
val to_meta : Set.t -> Meta_tag.t
