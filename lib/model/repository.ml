type user =
  { user : string
  ; repository : string
  }

type organization =
  { name : string
  ; project : string
  ; repository : string
  }

type t =
  | Github of user
  | Gitlab_user of user
  | Gitlab_org of organization
  | Tangled of user
  | Codeberg of user

let github_domain = "github.com"
let gitlab_domain = "gitlab.com"
let tangled_domain = "tangled.sh"
let codeberg_domain = "codeberg.org"
let github_url = Url.https github_domain
let gitlab_url = Url.https gitlab_domain
let tangled_url = Url.https tangled_domain
let codeberg_url = Url.https codeberg_domain

let forge_domain = function
  | Github _ -> github_domain
  | Gitlab_org _ | Gitlab_user _ -> gitlab_domain
  | Tangled _ -> tangled_domain
  | Codeberg _ -> codeberg_domain
;;

let forge_url = function
  | Github _ -> github_url
  | Gitlab_org _ | Gitlab_user _ -> gitlab_url
  | Tangled _ -> tangled_url
  | Codeberg _ -> codeberg_url
;;

let github_kind = [ github_domain; "github"; "gh" ]
let gitlab_kind = [ gitlab_domain; "gitlab"; "gl" ]
let tangled_kind = [ tangled_domain; "tangled"; "tl" ]
let codeberg_kind = [ codeberg_domain; "codeberg"; "cb" ]
let all_kind = github_kind @ gitlab_kind @ tangled_kind @ codeberg_kind

let kind_enum values =
  let open Yocaml.Data.Validation in
  string $ Field.tokenize
  & one_of ~pp:Format.pp_print_string ~equal:String.equal values
;;

let as_name =
  let open Yocaml.Data.Validation in
  string $ Field.tokenize $ Field.remove_arobase & Field.string_not_blank
;;

let required_repository o =
  let open Yocaml.Data.Validation in
  field (fetch o "repository") (option as_name)
  $? field (fetch o "repo") as_name
;;

let required_kind o =
  let open Yocaml.Data.Validation in
  field (fetch o "kind") (option (kind_enum all_kind))
  |? field (fetch o "provider") (option (kind_enum all_kind))
  $? field (fetch o "forge") (kind_enum all_kind)
;;

let of_kind ~user ~repository = function
  | k when List.exists (String.equal k) github_kind ->
    Ok (Github { user; repository })
  | k when List.exists (String.equal k) gitlab_kind ->
    Ok (Gitlab_user { user; repository })
  | k when List.exists (String.equal k) tangled_kind ->
    Ok (Tangled { user; repository })
  | k when List.exists (String.equal k) codeberg_kind ->
    Ok (Codeberg { user; repository })
  | k -> Yocaml.Data.Validation.fail_with ~given:k "Unknown kind"
;;

let validate_from_record_user v =
  let open Yocaml.Data.Validation in
  let* kind, user, repository =
    record
      (fun o ->
         let+ kind = required_kind o
         and+ user = required o "user" as_name
         and+ repository = required_repository o in
         kind, user, repository)
      v
  in
  of_kind ~user ~repository kind
;;

let validate_from_record_org =
  let open Yocaml.Data.Validation in
  record (fun o ->
    let+ _ = required_kind o
    and+ name = required o "name" as_name
    and+ project = required o "project" as_name
    and+ repository = required_repository o in
    Gitlab_org { name; project; repository })
;;

let validate_from_record =
  let open Yocaml.Data.Validation in
  validate_from_record_user / validate_from_record_org
;;

let split_path str_path = str_path |> String.split_on_char '/'

let ltrim_path = function
  | x :: xs when String.(equal (trim x)) "" -> xs
  | xs -> xs
;;

let record_from_path ?kind repo_path =
  let open Yocaml.Data in
  let k = "kind", option string kind in
  match ltrim_path repo_path with
  | user :: repository :: ([ "" ] | []) ->
    k :: [ "user", string user; "repository", string repository ] |> record
  | name :: project :: repository :: ([ "" ] | []) ->
    k
    :: [ "name", string name
       ; "project", string project
       ; "repository", string repository
       ]
    |> record
  | _ -> record [ k ]
;;

let validate_from_uri s =
  let uri = Uri.of_string s in
  let path = uri |> Uri.path |> split_path in
  let fields = record_from_path ?kind:(Uri.host uri) path in
  validate_from_record fields
;;

let validate_from_string s =
  let fields =
    match split_path s with
    | [] -> Yocaml.Data.record []
    | kind :: xs -> record_from_path ~kind xs
  in
  validate_from_record fields
;;

let validate =
  let open Yocaml.Data.Validation in
  validate_from_record / (string & (validate_from_string / validate_from_uri))
;;

let kind = function
  | Github _ -> "github"
  | Gitlab_org _ | Gitlab_user _ -> "gitlab"
  | Tangled _ -> "tangled"
  | Codeberg _ -> "codeberg"
;;

let component = function
  | Gitlab_org { name; project; repository } -> [ name; project; repository ]
  | Github { user; repository }
  | Gitlab_user { user; repository }
  | Tangled { user; repository }
  | Codeberg { user; repository } -> [ user; repository ]
;;

let home = function
  | Github { user; repository } ->
    Url.resolve (Yocaml.Path.abs [ user; repository ]) github_url
  | Gitlab_user { user; repository } ->
    Url.resolve (Yocaml.Path.abs [ user; repository ]) gitlab_url
  | Gitlab_org { name; project; repository } ->
    Url.resolve (Yocaml.Path.abs [ name; project; repository ]) gitlab_url
  | Codeberg { user; repository } ->
    Url.resolve (Yocaml.Path.abs [ user; repository ]) codeberg_url
  | Tangled { user; repository } ->
    Url.resolve (Yocaml.Path.abs [ "@" ^ user; repository ]) tangled_url
;;

let resolve path = function
  | (Gitlab_org _ | Gitlab_user _) as repo ->
    repo |> home |> Url.resolve Yocaml.Path.(relocate ~into:(rel [ "-" ]) path)
  | repo -> repo |> home |> Url.resolve path
;;

let clone_ssh repo =
  let domain = repo |> home |> Url.host in
  let suffix = repo |> component |> String.concat "/" in
  "git@" ^ domain ^ ":" ^ suffix ^ ".git"
;;

let clone_https = function
  | Tangled _ as repo -> repo |> home |> Url.to_string
  | repo ->
    repo
    |> home
    |> Url.on_path (Yocaml.Path.add_extension ".git")
    |> Url.to_string
;;

let bug_tracker = resolve (Yocaml.Path.rel [ "issues" ])

let blob ?(branch = "main") path = function
  | Codeberg _ as repo ->
    resolve
      Yocaml.Path.(relocate ~into:(rel [ "src"; "branch"; branch ]) path)
      repo
  | repo ->
    resolve Yocaml.Path.(relocate ~into:(rel [ "blob"; branch ]) path) repo
;;

let normalize repo =
  let open Yocaml.Data in
  let kind = kind repo
  and forge_domain = forge_domain repo
  and forge_url = forge_url repo
  and component = component repo
  and homepage = home repo
  and bug_tracker = bug_tracker repo in
  let ident = String.concat "/" component in
  record
    [ ( "forge"
      , record
          [ "name", string kind
          ; "url", Url.normalize @@ forge_url
          ; "domain", string forge_domain
          ] )
    ; "ident", string ident
    ; "compononent", list_of string component
    ; "homepage", Url.normalize homepage
    ; "bug_tracker", Url.normalize bug_tracker
    ; ( "clone"
      , record
          [ "ssh", string @@ clone_ssh repo
          ; "https", string @@ clone_https repo
          ] )
    ]
;;

let compare a b =
  let a = home a
  and b = home b in
  Url.compare a b
;;

module C = struct
  type nonrec t = t

  let compare = compare
  let normalize = normalize
  let validate = validate
end

module Set = Make.Set (C)
module Map = Make.Map (C)
