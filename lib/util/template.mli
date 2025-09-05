val chain
  :  Resolver.t
  -> string list
  -> ( unit
       , (module Yocaml.Required.DATA_INJECTABLE with type t = 'a)
         -> metadata:'a
         -> string
         -> string )
       Yocaml.Task.t
