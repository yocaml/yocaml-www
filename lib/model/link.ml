type t =
  { name : string
  ; url : Url.t
  ; description : string option
  }

let name { name; _ } = name
let url { url; _ } = url
let description { description; _ } = description

let validate_from_record =
  let open Yocaml.Data.Validation in
  record (fun o ->
    let+ name =
      field (fetch o "name") (option Field.not_blank)
      $? field (fetch o "title") Field.not_blank
    and+ url = field (fetch o "url") Url.validate
    and+ description =
      field (fetch o "description") (option Field.not_blank)
      |? field (fetch o "alt") (option Field.not_blank)
      |? field (fetch o "desc") (option Field.not_blank)
    in
    { name; url; description })
;;

let validate_from_url =
  let open Yocaml.Data.Validation in
  Url.validate
  $ fun url ->
  let name = Url.as_name url in
  { name; url; description = None }
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
