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

let resolve ?(on_query = `Remove) ({ path; uri; query; _ } as url) given_path =
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

let scheme_to_string = function
  | Http -> "http"
  | Https -> "https"
  | File -> "file"
  | Other x -> x
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

let validate =
  let open Yocaml.Data.Validation in
  string $ fun s -> s |> Uri.of_string |> of_uri
;;

let normalize { scheme; host; path = uri_path; port; query; uri } =
  let open Yocaml.Data in
  let query_string = Uri.verbatim_query uri in
  record
    [ "target", string @@ Uri.to_string uri
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
