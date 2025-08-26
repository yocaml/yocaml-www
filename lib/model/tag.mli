(** Describes a tag/keyword. *)

type t

val make : string -> t

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t

val of_list : string list -> Set.t
val set_to_string : Set.t -> string
