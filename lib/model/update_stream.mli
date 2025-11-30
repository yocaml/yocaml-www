(** Describe an event stream (a date associated to a label and to a
    set of authors). *)

type t

val empty : t
val authors : t -> Profile.Set.t
val on_description : (string -> string) -> t -> t
val max_date : t -> Yocaml.Datetime.t option
val resolve_authors : Configuration.t -> t -> t

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t
