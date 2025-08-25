type t =
  { local : string
  ; domain : string list
  }

let concat_local local =
  local |> List.map (function `String a | `Atom a -> a) |> String.concat "."
;;

let from_address = function
  | local, (`Domain domain, []) ->
    let local = concat_local local in
    Ok { local; domain }
  | given ->
    let given = Emile.address_to_string given in
    Yocaml.Data.Validation.fail_with ~given "Unsupported Email Scheme"
;;

let from_string given =
  given
  |> Emile.address_of_string
  |> function
  | Ok address -> from_address address
  | Error (`Invalid (a, b)) ->
    let err = Format.asprintf "Invalid `%s%s`" a b in
    Yocaml.Data.Validation.fail_with ~given err
;;

let validate =
  let open Yocaml.Data.Validation in
  string & from_string
;;

let normalize { local; domain } =
  let open Yocaml.Data in
  let cdomain = String.concat "." domain in
  let address = local ^ "@" ^ cdomain in
  record
    [ "address", string address
    ; "local", string local
    ; "domain", string cdomain
    ; "domain_fragments", list_of string domain
    ; ( "address_md5"
      , string
          (Digest.to_hex
           @@ Digest.string Stdlib.String.(lowercase_ascii @@ trim address)) )
    ]
;;
