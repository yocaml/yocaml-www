(** A representation of email addresses based on a simplified form of
    [Emile]. *)

type t

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t
