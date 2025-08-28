type t =
  | Website
  | Article of
      { published_time : Yocaml.Datetime.t
      ; updated_time : Yocaml.Datetime.t option
      ; section : string
      ; tags : Tag.Set.t
      }

let website = Website

let article ?updated_time ?(tags = Tag.Set.empty) ~published_time ~section () =
  Article { published_time; updated_time; section; tags }
;;

let to_open_graph = function
  | Website -> [ Meta_tag.make ~name:[ "og"; "type" ] "website" ]
  | Article { published_time; updated_time; section; tags } ->
    let open Meta_tag in
    let tags =
      tags
      |> Tag.Set.to_list
      |> List.map (from_value ~name:[ "article"; "tag" ] Tag.to_string)
    in
    [ make ~name:[ "og"; "type" ] "article"
    ; make
        ~name:[ "article"; "published_time" ]
        (Format.asprintf "%a" (Yocaml.Datetime.pp_rfc3339 ()) published_time)
    ; from_opt
        ~name:[ "article"; "modified_time" ]
        (Format.asprintf "%a" (Yocaml.Datetime.pp_rfc3339 ()))
        updated_time
    ; make ~name:[ "article"; "section" ] section
    ]
    @ tags
;;
