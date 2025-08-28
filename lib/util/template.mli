val chain
  :  (module Yocaml.Required.DATA_INJECTABLE with type t = 'a)
  -> Resolver.t
  -> string list
  -> ('a * string, 'a * string) Yocaml.Task.t
