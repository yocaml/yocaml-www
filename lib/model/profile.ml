type t =
  { display_name : string
  ; first_name : string option
  ; last_name : string option
  ; avatar : Url.t option
  ; website : Link.t option
  ; email : Email.t option
  ; x_account : string option
  ; mastodon_account : Link.t option
  ; bsky_account : string option
  ; more_accounts : Link.Set.t
  ; more_links : Link.Set.t
  ; more_emails : Email.t Util.Map.String.t
  ; custom_attributes : string Util.Map.String.t
  }

let make
      ?first_name
      ?last_name
      ?avatar
      ?website
      ?email
      ?x_account
      ?mastodon_account
      ?bsky_account
      ?(more_accounts = Link.Set.empty)
      ?(more_links = Link.Set.empty)
      ?(more_emails = Util.Map.String.empty)
      ?(custom_attributes = Util.Map.String.empty)
      display_name
  =
  { display_name
  ; first_name
  ; last_name
  ; avatar
  ; website
  ; email
  ; x_account
  ; mastodon_account
  ; bsky_account
  ; more_accounts
  ; more_links
  ; more_emails
  ; custom_attributes
  }
;;

let make_from_mailboix (display_name, email) = make ~email display_name
let trim = Yocaml.Data.Validation.(Field.not_blank $ String.trim)

let name_of_triple = function
  | Some dname, Some fname, Some lname -> Ok (dname, Some fname, Some lname)
  | None, Some fname, Some lname ->
    let dname = fname ^ " " ^ lname in
    Ok (dname, Some fname, Some lname)
  | Some dname, fname, lname -> Ok (dname, fname, lname)
  | None, Some n, None -> Ok (n, Some n, None)
  | None, None, Some n -> Ok (n, None, Some n)
  | None, None, None ->
    let error =
      Yocaml.Data.Validation.Missing_field { field = "display_name" }
    in
    Error (Yocaml.Nel.singleton error)
;;

let validate_name o =
  let open Yocaml.Data.Validation in
  let+ display_name =
    field o.${"display_name"} (option trim)
    |? field o.${"displayname"} (option trim)
    |? field o.${"username"} (option trim)
    |? field o.${"user_name"} (option trim)
    |? field o.${"uname"} (option trim)
    |? field o.${"name"} (option trim)
    |? field o.${"nick"} (option trim)
    |? field o.${"nick_name"} (option trim)
    |? field o.${"nickname"} (option trim)
  and+ first_name =
    field o.${"first_name"} (option trim)
    |? field o.${"firstname"} (option trim)
  and+ last_name =
    field o.${"last_name"} (option trim) |? field o.${"lastname"} (option trim)
  in
  display_name, first_name, last_name
;;

let validate_record =
  let open Yocaml.Data.Validation in
  record (fun o ->
    let+ display_name, first_name, last_name =
      (validate_name & name_of_triple) o
    and+ avatar = optional o "avatar" Url.validate
    and+ website = optional o "website" Link.validate
    and+ email = optional o "email" Email.validate
    and+ x_account = optional o "x_account" trim
    and+ bsky_account = optional o "bsky_account" trim
    and+ more_accounts = optional o "accounts" Link.Set.validate
    and+ more_links = optional o "links" Link.Set.validate
    and+ more_emails =
      optional o "emails" (Util.Map.String.validate Email.validate)
    and+ custom_attributes =
      optional o "attributes" (Util.Map.String.validate trim)
    and+ mastodon_account =
      optional
        o
        "mastodon_account"
        (record (fun m ->
           let+ n = required m "instance" Url.validate
           and+ username = required m "user" trim in
           Link.make ~name:username n))
    in
    make
      ?first_name
      ?last_name
      ?avatar
      ?website
      ?email
      ?x_account
      ?bsky_account
      ?mastodon_account
      ?more_accounts
      ?more_links
      ?more_emails
      ?custom_attributes
      display_name)
;;

let validate =
  let open Yocaml.Data.Validation in
  (string & Email.from_mailbox $ make_from_mailboix)
  / (trim $ make)
  / validate_record
;;

let normalize
      { display_name
      ; first_name
      ; last_name
      ; avatar
      ; website
      ; email
      ; x_account
      ; mastodon_account
      ; bsky_account
      ; more_accounts
      ; more_links
      ; more_emails
      ; custom_attributes
      }
  =
  let email, has_email =
    let open Util.Option in
    let e =
      email
      <|> (snd <$> Util.Map.String.find_first_opt (fun _ -> true) more_emails)
    in
    e, to_bool e
  in
  let open Yocaml.Data in
  record
    [ "display_name", string display_name
    ; "last_name", option string last_name
    ; "first_name", option string first_name
    ; "avatar", option Url.normalize avatar
    ; "website", option Link.normalize website
    ; "email", option Email.normalize email
    ; "x_account", option string x_account
    ; "mastodon_account", option Link.normalize mastodon_account
    ; "bsky_account", option string bsky_account
    ; "more_accounts", Link.Set.normalize more_accounts
    ; "more_links", Link.Set.normalize more_links
    ; "more_emails", Util.Map.String.normalize Email.normalize more_emails
    ; "attributes", Util.Map.String.normalize string custom_attributes
    ; "has_last_name", bool @@ Option.is_some last_name
    ; "has_first_name", bool @@ Option.is_some first_name
    ; "has_avatar", bool @@ Option.is_some avatar
    ; "has_website", bool @@ Option.is_some website
    ; "has_email", bool has_email
    ; "has_x_account", bool @@ Option.is_some x_account
    ; "has_mastodon_account", bool @@ Option.is_some mastodon_account
    ; "has_bsky_account", bool @@ Option.is_some bsky_account
    ]
;;

module C = struct
  type nonrec t = t

  let validate = validate
  let normalize = normalize

  let compare a b =
    (* Sufficient for defining set or map (because it is probably not
       usesful). *)
    let a = a |> normalize |> Format.asprintf "%a" Yocaml.Data.pp
    and b = b |> normalize |> Format.asprintf "%a" Yocaml.Data.pp in
    String.compare a b
  ;;
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)
