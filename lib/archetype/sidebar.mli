module Read : Yocaml.Required.DATA_READABLE
include Yocaml.Required.DATA_READABLE

val empty : t
val is_empty : t -> bool

val resolve
  :  (module Yocaml.Required.DATA_READABLE with type t = 'a)
  -> compute_source:(Yocaml.Path.t -> Yocaml.Path.t)
  -> compute_target:(Yocaml.Path.t -> Yocaml.Path.t)
  -> synthetize:('a -> string * string)
  -> (Read.t, t) Yocaml.Task.t

val normalize : t -> Yocaml.Data.t
val dump : t -> string
