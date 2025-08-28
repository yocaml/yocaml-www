type 'a t =
  { kind : Model.Document_kind.t
  ; title : string
  ; description : string
  ; tags : Model.Tag.Set.t
  ; source : Yocaml.Path.t option
  ; target : Yocaml.Path.t
  ; cover : Model.Cover.t option
  ; content : 'a
  ; configuration : Model.Configuration.t
  ; authors : Model.Profile.Set.t
  }

let make
      ?(authors = Model.Profile.Set.empty)
      ~kind
      ~title
      ~description
      ~tags
      ~source
      ~target
      ~cover
      ~configuration
      content
  =
  { title
  ; kind
  ; description
  ; tags
  ; source
  ; content
  ; configuration
  ; target
  ; cover
  ; authors
  }
;;

let normalize_meta_authors authors =
  authors
  |> Model.Profile.Set.to_list
  |> List.map (fun profile ->
    Model.Meta_tag.make ~name:[ "creator" ] (Model.Profile.display_name profile))
;;

let normalize_meta authors description tags =
  let open Model.Meta_tag in
  [ make ~name:[ "generator" ] "YOCaml"
  ; make ~name:[ "description" ] description
  ; Model.Tag.to_meta tags
  ]
  @ normalize_meta_authors authors
  |> normalize_list
;;

let normalize_og
      target_url
      { kind; configuration; title; description; cover; _ }
  =
  let open Model.Meta_tag in
  ([ make ~name:[ "og"; "site_name" ] (Model.Configuration.title configuration)
   ; make ~name:[ "og"; "url" ] (Model.Url.target target_url)
   ; make ~name:[ "og"; "title" ] title
   ; make ~name:[ "og"; "description" ] description
   ]
   @ Model.Document_kind.to_open_graph kind
   @ Option.(cover |> map Model.Cover.to_open_graph |> value ~default:[]))
  |> normalize_list
;;

let normalize
      on_content
      ({ title
       ; description
       ; tags
       ; content
       ; source
       ; configuration
       ; cover
       ; target
       ; authors
       ; kind = _
       } as doc)
  =
  let open Yocaml.Data in
  let site_repository = Model.Configuration.site_repository configuration in
  let source_url =
    Option.map
      (fun source -> Model.Repository.blob source site_repository)
      source
  in
  let slug =
    Option.map
      (fun source -> source |> Yocaml.Path.to_string |> Yocaml.Slug.from)
      source
  in
  let target_url =
    Model.Url.resolve target (Model.Configuration.main_url configuration)
  in
  let main_title = Model.Configuration.title configuration in
  let full_title = main_title ^ " - " ^ title in
  [ ( "document"
    , record
        [ "title", string title
        ; "full_title", string full_title
        ; "description", string description
        ; "tags", Model.Tag.Set.normalize tags
        ; "source_url", option Model.Url.normalize source_url
        ; "source", option path source
        ; "slug", option string slug
        ; "target", path target
        ; "cover", option Model.Cover.normalize cover
        ; "canonical", Model.Url.normalize target_url
        ; "meta", normalize_meta authors description tags
        ; "og", normalize_og target_url doc
        ; "authors", Model.Profile.Set.normalize authors
        ; "has_source", bool @@ Option.is_some source
        ; "has_cover", bool @@ Option.is_some cover
        ; "has_slug", bool @@ Option.is_some slug
        ] )
  ; on_content content
  ; "configuration", Model.Configuration.normalize configuration
  ]
;;
