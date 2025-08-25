(** The global and common configuration for the project. *)

type t

(** Retreive the source repository of the project. *)
val site_repository : t -> Repository.t

val title : t -> string
val subtitle : t -> string

(** {1 YOCaml related stuff} *)

(** Since the goal is not to be injected as a full template, but as a
    part of a generated artifact, we do not need to relay on
    [DATA_INJECTABLE]. *)
val normalize : t -> Yocaml.Data.t

include Yocaml.Required.DATA_READABLE with type t := t
