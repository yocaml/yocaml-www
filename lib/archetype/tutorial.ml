module Read = struct
  type t =
    { title : string
    ; description : string
    ; synopsis : string
    ; publication_date : Yocaml.Datetime.t
    ; tags : Model.Tag.Set.t
    ; authors : Model.Profile.Set.t
    ; table_of_content : bool
    ; cover : Model.Cover.t option
    ; updates : Model.Update_stream.t
    }

  let entity_name = "Tutorial"
  let neutral = Yocaml.Metadata.required entity_name

  let make
        ?(tags = Model.Tag.Set.empty)
        ?(authors = Model.Profile.Set.empty)
        ?(table_of_content = true)
        ?(updates = Model.Update_stream.empty)
        ?cover
        ~title
        ~description
        ~synopsis
        ~publication_date
        ()
    =
    { title
    ; description
    ; synopsis
    ; tags
    ; authors =
        Model.Profile.Set.union authors (Model.Update_stream.authors updates)
    ; publication_date
    ; table_of_content
    ; cover
    ; updates
    }
  ;;

  let text =
    let open Yocaml.Data.Validation in
    string $ String.trim
  ;;

  let validate =
    let open Yocaml.Data.Validation in
    record (fun o ->
      let+ title = required o "title" text
      and+ description = required o "description" text
      and+ synopsis = required o "synopsis" text
      and+ table_of_content = optional o "table_of_content" bool
      and+ cover = optional o "cover" Model.Cover.validate
      and+ tags = optional o "tags" Model.Tag.Set.validate
      and+ authors = optional o "authors" Model.Profile.Set.validate
      and+ updates = optional o "updates" Model.Update_stream.validate
      and+ publication_date = required o "date" Yocaml.Datetime.validate in
      make
        ?tags
        ?authors
        ?table_of_content
        ?cover
        ?updates
        ~title
        ~description
        ~synopsis
        ~publication_date
        ())
  ;;
end

type t =
  { tutorial : Read.t
  ; table_of_content : string option
  }

let markup f ({ tutorial; _ } as archetype) =
  { archetype with
    tutorial =
      Read.
        { tutorial with
          synopsis = f tutorial.synopsis
        ; updates = Model.Update_stream.on_description f tutorial.updates
        }
  }
;;

let make tutorial content =
  let content = Util.Markdown.of_string content in
  let meta =
    if tutorial.Read.table_of_content
    then (
      let table_of_content = Util.Markdown.table_of_content content in
      { tutorial; table_of_content })
    else { tutorial; table_of_content = None }
  in
  markup Util.Markdown.on_string meta, Util.Markdown.to_html content
;;

let normalize_content
      { tutorial =
          { title
          ; description
          ; synopsis
          ; publication_date
          ; tags
          ; authors
          ; cover
          ; updates
          ; table_of_content = _
          }
      ; table_of_content
      }
  =
  let open Yocaml.Data in
  ( "tutorial"
  , record
      [ "title", string title
      ; "description", string description
      ; "synopsis", string synopsis
      ; "publication_date", Yocaml.Datetime.normalize publication_date
      ; "tags", Model.Tag.Set.normalize tags
      ; "authors", Model.Profile.Set.normalize authors
      ; "cover", option Model.Cover.normalize cover
      ; "updates", Model.Update_stream.normalize updates
      ; "table_of_content", option string table_of_content
      ; "has_table_of_content", bool @@ Option.is_some table_of_content
      ] )
;;

let to_document ?source resolver applicative_task =
  let open Yocaml.Task in
  Env.configuration resolver
  &&& applicative_task
  >>| fun (configuration, (({ tutorial; _ } as archetype), content)) ->
  ( Html.Document.make
      ~configuration
      ~title:tutorial.title
      ~description:tutorial.description
      ~tags:tutorial.tags
      ~cover:tutorial.cover
      ~source
      archetype
  , content )
;;

module Html = struct
  type nonrec t = t Html.Document.t

  let normalize = Html.Document.normalize normalize_content
end
