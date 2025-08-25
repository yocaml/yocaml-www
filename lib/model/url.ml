type scheme =
  | Http
  | Https
  | File
  | Other of string

type t =
  { scheme : scheme
  ; host : string
  ; path : Yocaml.Path.t
  ; port : int option
  ; query : (string * string list) list
  ; uri : Uri.t
  }

let uri { uri; _ } = uri
let host { host; _ } = host
let to_string url = url |> uri |> Uri.to_string

let resolve ?(on_query = `Remove) given_path ({ path; uri; query; _ } as url) =
  let p =
    match Yocaml.Path.to_pair given_path with
    | `Root, _ -> given_path
    | `Rel, _ -> Yocaml.Path.relocate ~into:path given_path
  in
  let query =
    match on_query with
    | `Remove -> []
    | `Keep -> query
    | `Set query -> query
  in
  let uri =
    Uri.with_query (Uri.with_path uri (Yocaml.Path.to_string p)) query
  in
  { url with path = p; uri; query }
;;

let on_path f ({ uri; path; _ } as url) =
  let path = f path in
  let uri = Uri.with_path uri (Yocaml.Path.to_string path) in
  { url with uri; path }
;;

let scheme_to_string = function
  | Http -> "http"
  | Https -> "https"
  | File -> "file"
  | Other x -> x
;;

let as_name ?(with_scheme = false) ?(with_path = true) { host; path; scheme; _ }
  =
  let scheme = if with_scheme then scheme_to_string scheme ^ "://" else ""
  and path =
    if with_path then path |> Yocaml.Path.to_string |> Field.remove_dot else ""
  in
  scheme ^ host ^ path
;;

let scheme_of_string = function
  | None -> Https
  | Some scheme ->
    (match String.(trim (lowercase_ascii scheme)) with
     | "http" -> Http
     | "https" -> Https
     | "file" -> File
     | other_result -> Other other_result)
;;

let of_uri uri =
  let host = Uri.host_with_default ~default:"localhost" uri
  and path = Yocaml.Path.from_string @@ Uri.path uri
  and port = Uri.port uri
  and query = Uri.query uri
  and scheme = scheme_of_string @@ Uri.scheme uri in
  { uri; host; path; port; query; scheme }
;;

let of_string url = url |> Uri.of_string |> of_uri

let with_scheme ~scheme ?path rest =
  let url = scheme ^ "://" ^ rest |> of_string in
  Option.fold ~none:url ~some:(fun path -> resolve path url) path
;;

let http = with_scheme ~scheme:"http"
let https = with_scheme ~scheme:"https"
let file = with_scheme ~scheme:"file"

let validate =
  let open Yocaml.Data.Validation in
  string $ fun s -> s |> Uri.of_string |> of_uri
;;

let target u = u |> uri |> Uri.to_string

let normalize ({ scheme; host; path = uri_path; port; query; uri } as u) =
  let open Yocaml.Data in
  let query_string = Uri.verbatim_query uri in
  record
    [ "target", string @@ target u
    ; "scheme", string @@ scheme_to_string scheme
    ; "host", string host
    ; "path", path uri_path
    ; "port", option int port
    ; "query", list_of (pair string (list_of string)) query
    ; "query_string", option string query_string
    ; "has_port", bool @@ Option.is_some port
    ; "has_query_string", bool @@ Option.is_some query_string
    ]
;;

let compare a b = Uri.compare (uri a) (uri b)

module C = struct
  type nonrec t = t

  let compare = compare
  let normalize = normalize
  let validate = validate
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)
