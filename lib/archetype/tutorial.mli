(** Represents a tutorial. The main focus of this website. *)

(** The module used for reading tutorial. *)

module Read : sig
  include Yocaml.Required.DATA_READABLE

  val synthetize : t -> string * string
end

type t

val make : ?sidebar:Sidebar.t -> Read.t -> string -> t * string

val to_document
  :  ?source:Yocaml.Path.t
  -> target:Yocaml.Path.t
  -> Resolver.t
  -> (unit, t * 'a) Yocaml.Task.t
  -> (unit, t Html.Document.t * 'a) Yocaml.Task.t

module Html : sig
  type nonrec t = t Html.Document.t

  val normalize : t -> (string * Yocaml.Data.t) list
end
