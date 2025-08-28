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

let phrase_to_string list =
  list
  |> List.fold_left
       (fun (i, buf) -> function
          | `Dot -> succ i, buf ^ "."
          | `Word (`Atom s) | `Word (`String s) | `Encoded (s, _) ->
            let sep = if Int.equal i 0 then "" else " " in
            succ i, buf ^ sep ^ s)
       (0, "")
  |> snd
;;

let from_mailbox given =
  given
  |> Emile.of_string
  |> function
  | Ok Emile.{ name = Some name; local; domain } ->
    Result.map
      (fun email ->
         let display_name = phrase_to_string name in
         display_name, email)
      (from_address (local, domain))
  | Ok _ -> Yocaml.Data.Validation.fail_with ~given "Missing identity"
  | Error _ -> Yocaml.Data.Validation.fail_with ~given "Invalid mailbox"
;;

let validate =
  let open Yocaml.Data.Validation in
  string & from_string
;;

let make_domain { domain; _ } = String.concat "." domain
let make_address domain { local; _ } = local ^ "@" ^ domain

let to_string email =
  let domain = make_domain email in
  make_address domain email
;;

let normalize ({ local; domain } as e) =
  let open Yocaml.Data in
  let cdomain = make_domain e in
  let address = make_address cdomain e in
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

let compare a b =
  let a = to_string a
  and b = to_string b in
  String.compare a b
;;

module C = struct
  type nonrec t = t

  let compare = compare
  let normalize = normalize
  let validate = validate
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)
