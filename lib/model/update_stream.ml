type event =
  { authors : Profile.Set.t
  ; description : string
  }

type t = event Util.Map.Datetime.t

let make ?(authors = Profile.Set.empty) description = { authors; description }

let resolve_authors_on_event config { authors; description } =
  let authors =
    Profile.Set.map (Configuration.resolve_profile config) authors
  in
  make ~authors description
;;

let resolve_authors config =
  Util.Map.Datetime.map (resolve_authors_on_event config)
;;

let validate =
  Util.Map.Datetime.validate
    Yocaml.Data.Validation.(
      record (fun o ->
        let+ description = required o "description" (string $ Stdlib.String.trim)
        and+ authors = optional o "authors" Profile.Set.validate in
        make ?authors description))
;;

let max_date stream =
  stream |> Util.Map.Datetime.max_binding_opt |> Option.map fst
;;

let normalize dt =
  let last = max_date dt in
  Util.Map.Datetime.normalize
    ~reverse:true
    (fun { authors; description } ->
       let open Yocaml.Data in
       record
         [ "authors", Profile.Set.normalize authors
         ; "description", string description
         ; "last_update", option Yocaml.Datetime.normalize last
         ; "has_last_update", bool @@ Option.is_some last
         ])
    dt
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
