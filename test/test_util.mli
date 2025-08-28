val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result
val ( let+ ) : ('a, 'c) result -> ('a -> 'b) -> ('b, 'c) result
val validation : Yocaml.Data.t Yocaml.Data.Validation.validated_value -> unit
