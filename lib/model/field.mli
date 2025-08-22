(** Helpers for creating and validating template fields. *)

(** Ensure that the given value is a non empty string. *)
val not_blank : Yocaml.Data.t -> string Yocaml.Data.Validation.validated_value

(** Ensure that the given string is non empty. *)
val string_not_blank : string -> string Yocaml.Data.Validation.validated_value

(** Lowercase + trim. . *)
val tokenize : string -> string

(** Remove the arobase of a given string if it is the first character. *)
val remove_arobase : string -> string

(** Remove the dot of a given string if it is the first character. *)
val remove_dot : string -> string
