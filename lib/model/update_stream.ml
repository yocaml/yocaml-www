type event =
  { authors : Profile.Set.t
  ; description : string
  }

type t = event Util.Map.Datetime.t

let make ?(authors = Profile.Set.empty) description = { authors; description }

let validate =
  Util.Map.Datetime.validate
    Yocaml.Data.Validation.(
      record (fun o ->
        let+ description = required o "description" (string $ String.trim)
        and+ authors = optional o "authors" Profile.Set.validate in
        make ?authors description))
;;

let normalize =
  Util.Map.Datetime.normalize ~reverse:true (fun { authors; description } ->
    let open Yocaml.Data in
    record
      [ "authors", Profile.Set.normalize authors
      ; "description", string description
      ])
;;

let empty = Util.Map.Datetime.empty

let authors map =
  Util.Map.Datetime.fold
    (fun _ { authors; _ } set -> Profile.Set.union authors set)
    map
    Profile.Set.empty
;;

let on_description f map =
  Util.Map.Datetime.map
    (fun event -> { event with description = f event.description })
    map
;;
