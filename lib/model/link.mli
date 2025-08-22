(** A URL associated with a title and a potential description. *)

(** {1 Types} *)

type t

val name : t -> string
val url : t -> Url.t
val description : t -> string option

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t
