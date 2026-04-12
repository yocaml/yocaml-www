let entity_name = "Redirection"
let neutral = Yocaml.Metadata.required entity_name

type t =
  { target : Yocaml.Path.t
  ; delay : int
  }

let make ?(delay = 0) target = { target; delay }

let validate =
  let open Yocaml.Data.Validation in
  record (fun o ->
    let+ target = req o "target" ~alt:[ "path" ] path
    and+ delay = opt o "delay" ~alt:[ "duration"; "s" ] (int & Int.positive) in
    make ?delay target)
;;

let as_document ~configuration ~target archetype =
  Html.Document.make
    ~configuration
    ~source:None
    ~cover:None
    ~kind:Model.Document_kind.website
    ~title:"Redirection"
    ~description:(Model.Configuration.subtitle configuration)
    ~tags:Model.Tag.Set.empty
    ~target
    archetype
;;

let to_document ~target resolver task =
  let open Yocaml.Task in
  Env.configuration resolver
  &&& task
  >>| fun (configuration, (archetype, content)) ->
  as_document ~configuration ~target archetype, content
;;

let normalize_redirection { target; delay } =
  let open Yocaml.Data in
  "redirection", record [ "target", path target; "delay", int delay ]
;;

module Html = struct
  type nonrec t = t Html.Document.t

  let normalize = Html.Document.normalize normalize_redirection
end
