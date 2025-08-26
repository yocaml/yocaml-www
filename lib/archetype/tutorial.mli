(** Represents a tutorial. The main focus of this website. *)

(** The module used for reading tutorial. *)

module Read : sig
  include Yocaml.Required.DATA_READABLE
end

type t

val make : ('a -> string option) -> Read.t -> 'a -> t * 'a
val markup : (string -> string) -> t -> t
