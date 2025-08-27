module Path = Yocaml.Path

type t =
  { cache : Path.t
  ; source : Path.t
  ; target : Path.t
  ; server_root : Path.t
  }

let make
      ?(cache_folder = Path.rel [ "_cache" ])
      ?(source_folder = Path.rel [])
      ?(target_folder = Path.rel [ "_www" ])
      ?(server_root = Path.abs [])
      ()
  =
  { cache = cache_folder
  ; source = source_folder
  ; target = target_folder
  ; server_root
  }
;;

let trim ~prefix path =
  let kind_a, a = Path.to_pair prefix
  and kind_b, b = Path.to_pair path in
  let rec aux x y =
    match x, y with
    | [], ys -> ys
    | _, [] -> b
    | prefix_a :: xs, prefix_b :: ys when String.equal prefix_a prefix_b ->
      aux xs ys
    | _ -> b
  in
  match kind_a, kind_b with
  | `Rel, `Rel -> Path.rel (aux a b)
  | `Root, `Root -> Path.abs (aux a b)
  | `Root, `Rel | `Rel, `Root ->
    (* No common prefix *)
    path
;;

let binary = Path.from_string Sys.argv.(0)

module Source = struct
  let source { source; _ } = source
  let configuration r = Path.(source r / "configuration.toml")
  let assets r = Path.(source r / "assets")
  let css r = Path.(assets r / "css")
  let css_file r p = Path.(css r / p) |> Path.change_extension "css"
  let content r = Path.(source r / "content")
  let tutorial r = Path.(content r / "tutorial")
end

module Target = struct
  let target { target; server_root; _ } = Path.relocate ~into:target server_root
  let assets r = Path.(target r / "assets")
  let css r = Path.(assets r / "css")
  let css_file r = Path.(css r / "yocaml.css")
end

module Cache = struct
  let cache { cache; _ } = cache
  let global r = Path.(cache r / "yocaml")
end

module Server = struct
  let server { server_root; _ } = server_root

  let from_target r p =
    p |> trim ~prefix:(Target.target r) |> Path.relocate ~into:(server r)
  ;;
end
