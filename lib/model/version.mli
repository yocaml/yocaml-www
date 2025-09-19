type t

val compare : t -> t -> int

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> (t, Yocaml.Data.Validation.value_error) result
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t
