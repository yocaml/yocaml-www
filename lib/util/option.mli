(** Some helpers to deal with option. *)

type 'a t = 'a option =
  | None
  | Some of 'a

val map : ('a -> 'b) -> 'a t -> 'b t
val bind : 'a t -> ('a -> 'b t) -> 'b t
val unit : 'a t -> unit t
val of_bool : bool -> unit t
val to_bool : 'a t -> bool

module Syntax : sig
  val ( let+ ) : 'a t -> ('a -> 'b) -> 'b t
  val ( let* ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( and+ ) : 'a t -> 'b t -> ('a * 'b) t
  val ( and* ) : 'a t -> 'b t -> ('a * 'b) t
end

module Infix : sig
  val ( <$> ) : ('a -> 'b) -> 'a t -> 'b t
  val ( <$ ) : 'a -> 'b t -> 'a t
  val ( $> ) : 'a t -> 'b -> 'b t
  val ( >>= ) : 'a t -> ('a -> 'b t) -> 'b t
  val ( =<< ) : ('a -> 'b t) -> 'a t -> 'b t
  val ( >|= ) : 'a t -> ('a -> 'b) -> 'b t
  val ( <*> ) : ('a -> 'b) t -> 'a t -> 'b t
  val ( <|> ) : 'a t -> 'a t -> 'a t
end

include module type of Infix
include module type of Syntax
