(** Html regular meta tags. *)

(** A meta tag *)
type tag

(** The type describing a meta tag. *)
type t = tag option

val make_tag : name:string list -> string -> tag
val make : name:string list -> string -> t
val from : name:string list -> ('a -> string option) -> 'a -> t
val from_opt : name:string list -> ('a -> string) -> 'a option -> t
val from_value : name:string list -> ('a -> string) -> 'a -> t

(** {1 YOCaml related stuff} *)

val normalize : tag -> Yocaml.Data.t
val normalize_list : t list -> Yocaml.Data.t
