(** Try to represent the address of a source control
    repository. Currently, Gitlab, Github, Codeberg, and Tangled are
    supported. *)

(** {1 Types} *)

type t

(** {1 Repository manipulation} *)

(** [resolve path repo] will resolve a given [path] for a given [repo].*)
val resolve : Yocaml.Path.t -> t -> Url.t

(** Retreive the homepage of a repository. *)
val home : t -> Url.t

(** [blob ?branch path repo] compute the URl for a given [path] into a
    dedicated [repo]. *)
val blob : ?branch:string -> Yocaml.Path.t -> t -> Url.t

(** Retreive the bugtracker of a repository. *)
val bug_tracker : t -> Url.t

(** {1 YOCaml related stuff} *)

val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
val normalize : t -> Yocaml.Data.t
