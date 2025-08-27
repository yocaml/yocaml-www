type 'a line =
  { title : string
  ; links : 'a list
  }

type 'a raw = 'a line list

let make ?(links = []) title = { title; links }

module Read = struct
  type t = Yocaml.Path.t raw

  let entity_name = "Sidebar"
  let neutral = Yocaml.Metadata.required entity_name

  let validate =
    let open Yocaml.Data.Validation in
    (null & const [])
    / list_of
        (record (fun o ->
           let+ title = required o "title" Model.Field.not_blank
           and+ links = optional o "sections" (list_of path) in
           make ?links title))
  ;;
end

type entry =
  { name : string
  ; target : Yocaml.Path.t
  ; description : string
  }

type t = entry raw

let resolve
      (type a)
      (module S : Yocaml.Required.DATA_READABLE with type t = a)
      ~compute_source
      ~compute_target
      ~synthetize
  =
  let open Yocaml.Eff in
  Yocaml.Task.from_effect (fun side ->
    List.traverse
      (fun { title; links } ->
         let+ links =
           List.traverse
             (fun path ->
                let path = compute_source path in
                let+ meta, _ =
                  Yocaml_yaml.Eff.read_file_with_metadata
                    ~on:`Source
                    (module S)
                    path
                in
                let target = compute_target path
                and name, description = synthetize meta in
                { name; description; target })
             links
         in
         { title; links })
      side)
;;

let normalize =
  let open Yocaml.Data in
  list_of (fun { title; links } ->
    record
      [ "title", string title
      ; "is_empty", bool @@ List.is_empty links
      ; ( "sections"
        , list_of
            (fun { name; target; description } ->
               record
                 [ "name", string name
                 ; "target", path target
                 ; "description", string description
                 ])
            links )
      ])
;;

let dump side =
  side |> normalize |> Yocaml.Data.to_sexp |> Yocaml.Sexp.to_string
;;

let neutral = Ok []
let entity_name = "Sidebar"

let validate =
  let open Yocaml.Data.Validation in
  (null & const [])
  / list_of
      (record (fun o ->
         let+ title = required o "title" Model.Field.not_blank
         and+ links =
           optional
             o
             "sections"
             (list_of
                (record (fun k ->
                   let+ name = required k "name" Model.Field.not_blank
                   and+ target = required k "target" path
                   and+ description =
                     required k "description" Model.Field.not_blank
                   in
                   { name; target; description })))
         in
         make ?links title))
;;

let empty = []
let is_empty = List.is_empty
