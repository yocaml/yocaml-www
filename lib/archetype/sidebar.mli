module Read : Yocaml.Required.DATA_READABLE
include Yocaml.Required.DATA_READABLE

type entry

val entry
  :  name:string
  -> target:Yocaml.Path.t
  -> source:Yocaml.Path.t
  -> description:string
  -> to_be_done:bool
  -> entry

val of_list : (string * entry list) list -> t
val empty : t
val is_empty : t -> bool

val resolve
  :  (module Yocaml.Required.DATA_READABLE with type t = 'a)
  -> compute_source:(Yocaml.Path.t -> Yocaml.Path.t)
  -> compute_target:(Yocaml.Path.t -> Yocaml.Path.t)
  -> synthetize:('a -> string * string * bool)
  -> (Read.t, t) Yocaml.Task.t

val normalize : t -> Yocaml.Data.t
val dump : t -> string

module Reference : sig
  type t

  val normalize : t -> Yocaml.Data.t
end

val get_focus
  :  source:Yocaml.Path.t
  -> t
  -> Reference.t option * Reference.t option
