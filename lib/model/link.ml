type t =
  { name : string
  ; url : Url.t
  ; description : string option
  }

let make ?name ?description url =
  let name =
    match name with
    | None -> Url.as_name url
    | Some name -> name
  in
  { name; description; url }
;;

let name { name; _ } = name
let url { url; _ } = url
let description { description; _ } = description

let validate_from_record =
  let open Yocaml.Data.Validation in
  record (fun o ->
    let+ name =
      field (fetch o "name") (option Field.not_blank)
      |? field (fetch o "title") (option Field.not_blank)
    and+ url = field (fetch o "url") Url.validate
    and+ description =
      field (fetch o "description") (option Field.not_blank)
      |? field (fetch o "alt") (option Field.not_blank)
      |? field (fetch o "desc") (option Field.not_blank)
    in
    make ?name ?description url)
;;

let validate_from_url =
  let open Yocaml.Data.Validation in
  Url.validate $ fun url -> make url
;;

let validate =
  let open Yocaml.Data.Validation in
  validate_from_record / validate_from_url
;;

let normalize { name; url; description } =
  let open Yocaml.Data in
  record
    [ "name", string name
    ; "url", Url.normalize url
    ; "description", option string description
    ; "has_description", bool @@ Option.is_some description
    ]
;;

let normalize_as_string { name; url; description } =
  name ^ Url.to_string url ^ Option.value ~default:"" description
;;

let compare a b = String.compare (normalize_as_string a) (normalize_as_string b)

module C = struct
  type nonrec t = t

  let compare = compare
  let normalize = normalize
  let validate = validate
end

module Set = Make.Set (C)
module Map = Make.Map (C)
