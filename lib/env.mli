(** An extension of the YOCaml interpreter to support ‘magic’
    configuration provisioning. *)

(** Retreive the configuration. *)
val get_configuration : unit -> Model.Configuration.t Yocaml.Eff.t

(** An arrow that retreive the configuration. *)
val configuration : Resolver.t -> (unit, Model.Configuration.t) Yocaml.Task.t

(** An handler for handling configuration at the execution level. *)
val handle : Resolver.t -> (unit -> 'a Yocaml.Eff.t) -> unit -> 'a Yocaml.Eff.t
