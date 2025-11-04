(** Helpers for creating and validating template fields. *)

(** Lowercase + trim. . *)
val tokenize : string -> string

(** Remove the arobase of a given string if it is the first character. *)
val remove_arobase : string -> string

(** Remove the dot of a given string if it is the first character. *)
val remove_dot : string -> string

(** Remove the hash of a given string if it is the first character. *)
val remove_hash : string -> string
