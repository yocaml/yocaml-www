type t =
  { title : string
  ; subtitle : string
  ; main_url : Url.t
  ; site_repository : Repository.t
  ; yocaml_repository : Repository.t
  ; software_license : Link.t
  ; content_license : Link.t
  }

let entity_name = "configuration"
let neutral = Yocaml.Metadata.required entity_name
let site_repository { site_repository; _ } = site_repository
let title { title; _ } = title
let subtitle { subtitle; _ } = subtitle

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
    let+ title = required fields "title" Field.not_blank
    and+ subtitle = required fields "subtitle" Field.not_blank
    and+ main_url = required fields "main_url" Url.validate
    and+ site_repository = required fields "site_repository" Repository.validate
    and+ yocaml_repository =
      required fields "yocaml_repository" Repository.validate
    and+ software_license = required fields "software_license" Link.validate
    and+ content_license = required fields "content_license" Link.validate in
    { title
    ; subtitle
    ; main_url
    ; site_repository
    ; yocaml_repository
    ; software_license
    ; content_license
    })
;;

let normalize
      { title
      ; subtitle
      ; main_url
      ; site_repository
      ; yocaml_repository
      ; software_license
      ; content_license
      }
  =
  let open Yocaml.Data in
  record
    [ "title", string title
    ; "subtitle", string subtitle
    ; "main_url", Url.normalize main_url
    ; "site_repository", Repository.normalize site_repository
    ; "yocaml_repository", Repository.normalize yocaml_repository
    ; "software_license", Link.normalize software_license
    ; "content_license", Link.normalize content_license
    ]
;;
