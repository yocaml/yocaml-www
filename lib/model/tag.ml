type t = string

let make s = String.trim s
let to_string s = s

let validate =
  let open Yocaml.Data.Validation in
  string $ make $ Field.remove_hash & Field.string_not_blank
;;

let normalize t =
  let open Yocaml.Data in
  record [ "value", string t; "slug", t |> Yocaml.Slug.from |> string ]
;;

module C = struct
  type nonrec t = t

  let validate = validate
  let normalize = normalize
  let compare a b = String.compare a b
end

module Set = Util.Set.Make (C)
module Map = Util.Map.Make (C)

let of_list = List.fold_left (fun set tag -> Set.add (make tag) set) Set.empty
let set_to_string set = set |> Set.to_list |> String.concat ", "

let to_meta tags =
  if Set.is_empty tags
  then None
  else
    Meta_tag.from_value ~name:[ "keywords" ] (fun s -> s |> set_to_string) tags
;;
