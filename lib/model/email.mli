(** A representation of email addresses based on a simplified form of
    [Emile]. *)

(** The type describing an Email address. *)
type t

(** Convert an email address into a string. *)
val to_string : t -> string

(** Lexical comparison between emails. *)
val compare : t -> t -> int

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t

(** {1 Set and Map} *)

module Set : Specs.SET with type elt = t
module Map : Specs.MAP with type key = t
