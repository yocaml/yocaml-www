module Make (O : Specs.ORDERED_TYPE) : Specs.SET with type elt = O.t
module String : Specs.SET with type elt = String.t
module Path : Specs.SET with type elt = Yocaml.Path.t
