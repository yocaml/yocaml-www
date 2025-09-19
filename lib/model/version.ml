type t =
  { major : int
  ; minor : int
  ; patch : int
  ; identifier : string option
  }

let on_string str =
  match str with
  | Yocaml.Data.String x ->
    (match String.split_on_char '-' x with
     | v :: identifier ->
       let identifier =
         match identifier with
         | [] -> None
         | _ :: _ -> Some (String.concat "-" identifier)
       in
       (match String.split_on_char '.' v with
        | [ major; minor; patch ] ->
          let open Yocaml.Data in
          Ok
            (record
               [ "major", option int (int_of_string_opt major)
               ; "minor", option int (int_of_string_opt minor)
               ; "patch", option int (int_of_string_opt patch)
               ; "identifier", option string identifier
               ])
        | _ -> Ok str)
     | _ -> Ok str)
  | x -> Ok x
;;

let validate =
  let open Yocaml.Data.Validation in
  on_string
  & record (fun fields ->
    let+ major = required fields "major" (int & positive)
    and+ minor = required fields "minor" (int & positive)
    and+ patch = required fields "patch" (int & positive)
    and+ identifier = optional fields "identifier" string in
    { major; minor; patch; identifier })
;;

let to_string { major; minor; patch; identifier } =
  let identifier =
    match identifier with
    | None -> ""
    | Some i -> "-" ^ i
  in
  Format.asprintf "%d.%d.%d%s" major minor patch identifier
;;

let normalize ({ major; minor; patch; identifier } as v) =
  let open Yocaml.Data in
  record
    [ "major", int major
    ; "minor", int minor
    ; "patch", int patch
    ; "identifier", option string identifier
    ; "has_iddentifier", bool @@ Option.is_some identifier
    ; "repr", string @@ to_string v
    ; "repr_v", string @@ "v" ^ to_string v
    ]
;;

let compare_identifier a b =
  match a, b with
  | None, None -> 0
  | Some _, None -> -1
  | None, Some _ -> 1
  | Some a, Some b -> String.compare a b
;;

let compare { major; minor; patch; identifier } b =
  let c = Int.compare major b.major in
  if Int.equal c 0
  then (
    let c = Int.compare minor b.minor in
    if Int.equal c 0
    then (
      let c = Int.compare patch b.patch in
      if Int.equal c 0 then compare_identifier identifier b.identifier else c)
    else c)
  else c
;;

module C = struct
  type nonrec t = t

  let validate = validate
  let normalize = normalize
  let compare = compare
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)
