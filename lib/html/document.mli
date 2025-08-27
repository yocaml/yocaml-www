(** Describes an HTML document. Builds a complete set of metadata to
    generate an HTML page. *)

type 'a t

val make
  :  title:string
  -> description:string
  -> tags:Model.Tag.Set.t
  -> source:Yocaml.Path.t option
  -> cover:Model.Cover.t option
  -> configuration:Model.Configuration.t
  -> 'a
  -> 'a t

(** {1 YOCaml related stuff} *)

val normalize
  :  ('a -> string * Yocaml.Data.t)
  -> 'a t
  -> (string * Yocaml.Data.t) list
