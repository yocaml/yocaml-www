(** Helpers for constructing complex but injectable/validatable
    data. *)

module Set (O : Specs.ORDERED_TYPE) : Specs.SET with type elt = O.t
module Map (O : Specs.ORDERED_TYPE) : Specs.MAP with type key = O.t
