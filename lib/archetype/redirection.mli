(** A Simple redirection. *)

include Yocaml.Required.DATA_READABLE

val as_document
  :  configuration:Model.Configuration.t
  -> target:Yocaml.Path.t
  -> t
  -> t Html.Document.t

val to_document
  :  target:Yocaml.Path.t
  -> Resolver.t
  -> (unit, t * 'a) Yocaml.Task.t
  -> (unit, t Html.Document.t * 'a) Yocaml.Task.t

module Html : sig
  type nonrec t = t Html.Document.t

  val normalize : t -> (string * Yocaml.Data.t) list
end
