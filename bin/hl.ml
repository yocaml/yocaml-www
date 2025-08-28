open Yocaml

let grammars = Path.rel [ "assets"; "grammars" ]
let lib = Path.(grammars / "lib")
let track_binary = Pipeline.track_file (Path.from_string Sys.argv.(0))

let dune_file =
  {|
(library
  (name yocaml_grammars)
  (public_name yocaml-www.yocaml_grammars))
|}
;;

let make_dune_file =
  Action.Static.write_file
    Path.(lib / "dune")
    Task.(track_binary >>> const dune_file)
;;

let process_grammars =
  Batch.iter_files ~where:(Path.has_extension "json") grammars (fun file ->
    let target = file |> Path.move ~into:lib |> Path.change_extension "ml" in
    let action =
      let open Task in
      let+ json = Pipeline.read_file file in
      let value = Yojson.Basic.from_string json in
      let exprs = Yojson.Basic.show value in
      "let value = \n\t" ^ exprs ^ "\n"
    in
    Action.Static.write_file target action)
;;

let discard_cache _ = Eff.return ()

let () =
  Yocaml_unix.run ~level:`Debug (fun () ->
    let open Eff in
    return Cache.empty >>= make_dune_file >>= process_grammars >>= discard_cache)
;;
