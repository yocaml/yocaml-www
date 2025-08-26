type tag =
  { name : string
  ; content : string
  }

type t = tag option

let make_tag ~name content = { name = String.concat ":" name; content }
let make ~name content = make_tag ~name content |> Option.some
let from ~name f x = x |> f |> Option.map (make_tag ~name)
let from_opt ~name f x = from ~name (Option.map f) x
let from_value ~name f = from ~name (fun x -> x |> f |> Option.some)

let normalize { name; content } =
  let open Yocaml.Data in
  record [ "name", string name; "content", string content ]
;;

let normalize_list xs =
  let open Yocaml.Data in
  xs |> List.filter_map Fun.id |> list_of normalize
;;
