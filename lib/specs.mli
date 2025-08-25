module type ORDERED_TYPE = sig
  type t

  val compare : t -> t -> int
  val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
  val normalize : t -> Yocaml.Data.t
end

module type SET = sig
  include Stdlib.Set.S

  val validate : Yocaml.Data.t -> t Yocaml.Data.Validation.validated_value
  val normalize : t -> Yocaml.Data.t
end

module type MAP = sig
  include Stdlib.Map.S

  val validate
    :  (Yocaml.Data.t -> 'a Yocaml.Data.Validation.validated_value)
    -> Yocaml.Data.t
    -> 'a t Yocaml.Data.Validation.validated_value

  val normalize : ('a -> Yocaml.Data.t) -> 'a t -> Yocaml.Data.t
end
