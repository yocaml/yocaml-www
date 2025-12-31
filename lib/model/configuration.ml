type t =
  { title : string
  ; subtitle : string
  ; main_url : Url.t
  ; site_repository : Repository.t
  ; yocaml_repository : Repository.t
  ; software_license : Link.t
  ; content_license : Link.t
  ; authors : Profile.Set.t
  }

let entity_name = "configuration"
let neutral = Yocaml.Metadata.required entity_name
let site_repository { site_repository; _ } = site_repository
let title { title; _ } = title
let subtitle { subtitle; _ } = subtitle
let main_url { main_url; _ } = main_url

let resolve_profile { authors; _ } profile =
  authors
  |> Profile.Set.find_first_opt (fun d ->
    String.equal (Profile.display_name profile) (Profile.display_name d))
  |> Option.map (Profile.merge profile)
  |> Option.value ~default:profile
;;

let make
      ?(authors = Profile.Set.empty)
      ~title
      ~subtitle
      ~main_url
      ~site_repository
      ~yocaml_repository
      ~software_license
      ~content_license
      ()
  =
  { title
  ; subtitle
  ; main_url
  ; site_repository
  ; yocaml_repository
  ; software_license
  ; content_license
  ; authors
  }
;;

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
    let+ title = required fields "title" (string & String.not_blank)
    and+ subtitle = required fields "subtitle" (string & String.not_blank)
    and+ main_url = required fields "main_url" Url.validate
    and+ site_repository = required fields "site_repository" Repository.validate
    and+ yocaml_repository =
      required fields "yocaml_repository" Repository.validate
    and+ software_license = required fields "software_license" Link.validate
    and+ content_license = required fields "content_license" Link.validate
    and+ authors = optional fields "authors" Profile.Set.validate in
    make
      ?authors
      ~title
      ~subtitle
      ~main_url
      ~site_repository
      ~yocaml_repository
      ~software_license
      ~content_license
      ())
;;

let normalize
      { title
      ; subtitle
      ; main_url
      ; site_repository
      ; yocaml_repository
      ; software_license
      ; content_license
      ; authors
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
    ; "authors", Profile.Set.normalize authors
    ]
;;
