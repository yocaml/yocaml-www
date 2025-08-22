(** Helpers for creating and validating template fields. *)

(** Ensure that the given value is a non empty string. *)
val not_blank : Yocaml.Data.t -> string Yocaml.Data.Validation.validated_value

(** Ensure that the given string is non empty. *)
val string_not_blank : string -> string Yocaml.Data.Validation.validated_value

(** Lowercase + trim. . *)
val tokenize : string -> string

(** Remove the first arobase of a given string. *)
val remove_arobase : string -> string
