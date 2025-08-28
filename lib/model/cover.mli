(** Deal with Cover (for Open Graph data). *)

type t

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t

(** {1 Opengraph related stuff} *)

val to_open_graph : t -> Meta_tag.t list
