let track_binary = Yocaml.Pipeline.track_file Resolver.binary

let css resolver =
  let open Yocaml.Task in
  let target = Resolver.Target.css_file resolver in
  Yocaml.Action.Static.write_file
    target
    (track_binary
     >>> Yocaml.Pipeline.pipe_files
           ~separator:"\n"
           ([ "reset"; "syntax"; "style" ]
            |> List.map (Resolver.Source.css_file resolver)))
;;

let tutorial _ _ = assert false

(* let tutorial resolver source = *)
(*   let open Yocaml.Task in *)
(*   let content = *)
(*     let+ meta, content = *)
(*       Yocaml_yaml.Pipeline.read_file_with_metadata *)
(*         (module Archetype.Tutorial.Read) *)
(*         source *)
(*     in *)
(*     assert false *)
(*   in *)
(*   assert false *)
(* ;; *)

let tutorials resolver =
  Yocaml.Batch.iter_files
    (Resolver.Source.tutorial resolver)
    (tutorial resolver)
;;

let run ~resolver () =
  let open Yocaml.Eff in
  let cache_file = Resolver.Cache.global resolver in
  Yocaml.Action.restore_cache cache_file
  >>= css resolver
  >>= tutorials resolver
  >>= Yocaml.Action.store_cache cache_file
;;
