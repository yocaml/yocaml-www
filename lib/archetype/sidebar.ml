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
           let+ title = required o "title" (string & String.not_blank)
           and+ links = optional o "sections" (list_of path) in
           make ?links title))
  ;;
end

type entry =
  { name : string
  ; target : Yocaml.Path.t
  ; source : Yocaml.Path.t
  ; description : string
  ; to_be_done : bool
  }

type t = entry raw

let entry ~name ~target ~source ~description ~to_be_done =
  { name; target; source; description; to_be_done }
;;

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
                let source = compute_source path in
                let+ meta, _ =
                  Yocaml_yaml.Eff.read_file_with_metadata
                    ~on:`Source
                    (module S)
                    source
                in
                let target = compute_target path
                and name, description, to_be_done = synthetize meta in
                { name; description; target; source; to_be_done })
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
            (fun { name; target; description; source; to_be_done } ->
               let slug = source |> Yocaml.Path.to_string |> Yocaml.Slug.from in
               record
                 [ "name", string name
                 ; "target", path target
                 ; "description", string description
                 ; "source", path source
                 ; "slug", string slug
                 ; "to_be_done", bool to_be_done
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
         let+ title = required o "title" (string & String.not_blank)
         and+ links =
           optional
             o
             "sections"
             (list_of
                (record (fun k ->
                   let+ name = required k "name" (string & String.not_blank)
                   and+ target = required k "target" path
                   and+ source = required k "source" path
                   and+ to_be_done =
                     optional_or ~default:false k "to_be_done" bool
                   and+ description =
                     required k "description" (string & String.not_blank)
                   in
                   { name; target; description; source; to_be_done })))
         in
         make ?links title))
;;

let empty = []
let is_empty = List.is_empty

module Reference = struct
  type t =
    { title : string
    ; name : string
    ; description : string
    ; target : Yocaml.Path.t
    }

  let normalize { title; name; description; target } =
    let open Yocaml.Data in
    record
      [ "title", string title
      ; "name", string name
      ; "description", string description
      ; "target", path target
      ]
  ;;
end

let hd_opt = function
  | x :: _ -> Some x
  | _ -> None
;;

let rec first_not_empty = function
  | { links = []; _ } :: xs -> first_not_empty xs
  | x :: _ -> Some x
  | [] -> None
;;

let from_focus (title, { name; description; target; _ }) =
  Reference.{ title; name; description; target }
;;

let get_focus ~source:given_source side =
  let rec on_links section prev = function
    | { source; _ } :: xs when Yocaml.Path.equal source given_source ->
      prev, Some source, xs |> hd_opt |> Option.map (fun x -> section, x)
    | x :: xs -> on_links section (Some (section, x)) xs
    | [] -> prev, None, None
  in
  let rec aux prev = function
    | [] -> prev, None
    | { title; links } :: xs ->
      let p, c, n = on_links title prev links in
      (match c, n with
       | Some _, Some y -> p, Some y
       | Some _, None ->
         ( p
         , Option.bind (first_not_empty xs) (fun { title; links } ->
             links |> hd_opt |> Option.map (fun x -> title, x)) )
       | None, None | None, Some _ -> aux p xs)
  in
  let prev, next = aux None side in
  prev |> Option.map from_focus, next |> Option.map from_focus
;;

let of_list l = List.map (fun (title, links) -> { title; links }) l
