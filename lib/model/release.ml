type change =
  { label : string
  ; authors : Profile.t list
  }

type t =
  { city : string option
  ; country : string option
  ; date : Yocaml.Datetime.t
  ; version : Version.t
  ; note : string option
  ; changelog : (string * change list) list
  ; url : Url.t
  }

let entity_name = "Release"
let neutral = Yocaml.Metadata.required entity_name

let compare a b =
  let v = Version.compare a.version b.version in
  if Int.equal v 0 then Yocaml.Datetime.compare a.date b.date else v
;;

let validate_change =
  let open Yocaml.Data.Validation in
  record (fun fields ->
    let+ label = required fields "label" string
    and+ authors = required fields "authors" (list_of Profile.validate) in
    { label; authors })
;;

let validate_changes =
  let open Yocaml.Data.Validation in
  record (fun fields ->
    let+ plugin = required fields "plugin" string
    and+ changes =
      optional_or ~default:[] fields "changes" (list_of validate_change)
    in
    plugin, changes)
;;

let validate =
  let open Yocaml.Data.Validation in
  record (fun fields ->
    let+ version = required fields "version" Version.validate
    and+ date = required fields "date" Yocaml.Datetime.validate
    and+ note = optional fields "note" string
    and+ city = optional fields "city" string
    and+ url = required fields "url" Url.validate
    and+ country = optional fields "country" string
    and+ changelog =
      optional_or ~default:[] fields "changelog" (list_of validate_changes)
    in
    { version; city; country; date; note; changelog; url })
;;

let get_data changelog =
  List.fold_left
    (fun (plugins, profiles) (plugin, changes) ->
       ( Util.Set.String.add plugin plugins
       , List.fold_left
           (fun profiles { authors; _ } ->
              Profile.Set.union (Profile.Set.of_list authors) profiles)
           profiles
           changes ))
    (Util.Set.String.empty, Profile.Set.empty)
    changelog
;;

let normalize { version; city; country; date; note; changelog; url } =
  let open Yocaml.Data in
  let plugins, profiles = get_data changelog in
  record
    [ "version", Version.normalize version
    ; "url", Url.normalize url
    ; "city", option string city
    ; "country", option string country
    ; "date", Yocaml.Datetime.normalize date
    ; "note", option string note
    ; ( "changelog"
      , list_of
          (fun (plugin, changes) ->
             record
               [ "plugin", string plugin
               ; "has_changes", bool @@ List.is_empty changes
               ; ( "changes"
                 , list_of
                     (fun { label; authors } ->
                        record
                          [ "label", string label
                          ; "authors", list_of Profile.normalize authors
                          ])
                     changes )
               ])
          changelog )
    ; "has_city", bool @@ Option.is_some city
    ; "has_country", bool @@ Option.is_some country
    ; "has_note", bool @@ Option.is_some note
    ; "has_changelog", bool @@ List.is_empty changelog
    ; "profiles", Profile.Set.normalize profiles
    ; "plugins", Util.Set.String.normalize plugins
    ]
;;

module C = struct
  type nonrec t = t

  let validate = validate
  let normalize = normalize
  let compare a b = compare b a
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)
