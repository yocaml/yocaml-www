type 'a t =
  { title : string
  ; description : string
  ; tags : Model.Tag.Set.t
  ; source : Yocaml.Path.t option
  ; cover : Model.Cover.t option
  ; content : 'a
  ; configuration : Model.Configuration.t
  }

let make ~title ~description ~tags ~source ~cover ~configuration content =
  { title; description; tags; source; content; configuration; cover }
;;

let normalize_meta description tags =
  let open Model.Meta_tag in
  [ make ~name:[ "generator" ] "YOCaml"
  ; make ~name:[ "description" ] description
  ; Model.Tag.to_meta tags
  ]
  |> normalize_list
;;

let normalize
      on_content
      { title; description; tags; content; source; configuration; cover }
  =
  let open Yocaml.Data in
  let site_repository = Model.Configuration.site_repository configuration in
  let source_url =
    Option.map
      (fun source -> Model.Repository.blob source site_repository)
      source
  in
  let main_title = Model.Configuration.title configuration in
  let full_title = main_title ^ " - " ^ title in
  record
    [ ( "document"
      , record
          [ "title", string title
          ; "full_title", string full_title
          ; "description", string description
          ; "tags", Model.Tag.Set.normalize tags
          ; "source", option Model.Url.normalize source_url
          ; "cover", option Model.Cover.normalize cover
          ; "meta", normalize_meta description tags
          ; "has_source", bool @@ Option.is_some source
          ; "has_cover", bool @@ Option.is_some cover
          ] )
    ; on_content content
    ]
;;
