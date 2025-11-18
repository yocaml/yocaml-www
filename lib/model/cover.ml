type kind =
  | Image
  | Video

type t =
  { kind : kind
  ; url : Url.t
  ; secure_url : Url.t option
  ; mime_type : string option
  ; dimension : (int * int) option
  ; alt : string option
  }

let make ~kind ?secure_url ?mime_type ?dimension ?alt url =
  { kind; url; secure_url; mime_type; dimension; alt }
;;

let compare a b = Url.compare a.url b.url

let kind_to_string = function
  | Image -> "image"
  | Video -> "video"
;;

let validate_kind =
  let open Yocaml.Data.Validation in
  string $ Field.tokenize
  & one_of
      ~pp:Format.pp_print_string
      ~equal:Stdlib.String.equal
      [ "video"; "image" ]
    $ function
    | "video" -> Video
    | _ -> Image
;;

let validate =
  let open Yocaml.Data.Validation in
  (Url.validate $ make ~kind:Image)
  / record (fun o ->
    let+ kind = required o "kind" validate_kind
    and+ url = required o "url" Url.validate
    and+ mime_type =
      field o.${"type"} (option Field.not_blank)
      |? field o.${"mime_type"} (option Field.not_blank)
    and+ width =
      field o.${"width"} (option (int & positive))
      |? field o.${"w"} (option (int & positive))
    and+ height =
      field o.${"height"} (option (int & positive))
      |? field o.${"h"} (option (int & positive))
    and+ secure_url = optional o "secure_url" Url.validate
    and+ alt = optional o "alt" Field.not_blank in
    let dimension = Util.Option.((fun x y -> x, y) <$> width <*> height) in
    make ~kind ?mime_type ?dimension ?secure_url ?alt url)
;;

let normalize { kind; url; secure_url; mime_type; dimension; alt } =
  let open Yocaml.Data in
  record
    [ "kind", string (kind_to_string kind)
    ; "url", Url.normalize url
    ; "secure_url", option Url.normalize secure_url
    ; "mime_type", option string mime_type
    ; "width", option (fun x -> x |> fst |> int) dimension
    ; "height", option (fun x -> x |> snd |> int) dimension
    ; "alt", option string alt
    ]
;;

module C = struct
  type nonrec t = t

  let compare = compare
  let validate = validate
  let normalize = normalize
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)

let to_open_graph { kind; url; secure_url; mime_type; dimension; alt } =
  let k = kind_to_string kind in
  let name = [ "og"; k ] in
  let mk x = name @ [ x ] in
  [ Meta_tag.make ~name (Url.target url)
  ; Meta_tag.from_opt ~name:(mk "secure_url") Url.target secure_url
  ; Meta_tag.from_opt ~name:(mk "type") Fun.id mime_type
  ; Meta_tag.from_opt
      ~name:(mk "width")
      (fun (w, _) -> string_of_int w)
      dimension
  ; Meta_tag.from_opt
      ~name:(mk "height")
      (fun (_, h) -> string_of_int h)
      dimension
  ; Meta_tag.from_opt ~name:(mk "alt") Fun.id alt
  ]
;;
