type t

val website : t

val article
  :  ?updated_time:Yocaml.Datetime.t
  -> ?tags:Tag.Set.t
  -> published_time:Yocaml.Datetime.t
  -> section:string
  -> unit
  -> t

(** {1 Opengraph related stuff} *)

val to_open_graph : t -> Meta_tag.t list
