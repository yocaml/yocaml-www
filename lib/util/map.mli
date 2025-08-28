module Make (O : Specs.ORDERED_TYPE) : Specs.MAP with type key = O.t
module String : Specs.MAP with type key = String.t
module Path : Specs.MAP with type key = Yocaml.Path.t
module Datetime : Specs.MAP with type key = Yocaml.Datetime.t
