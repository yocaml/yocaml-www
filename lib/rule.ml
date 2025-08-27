module Tutorial = Archetype.Tutorial
open Yocaml

let track_binary = Pipeline.track_file Resolver.binary

let css resolver =
  let open Task in
  let target = Resolver.Target.css_file resolver in
  Action.Static.write_file
    target
    (track_binary
     >>> Pipeline.pipe_files
           ~separator:"\n"
           ([ "reset"; "syntax"; "style" ]
            |> List.map (Resolver.Source.css_file resolver)))
;;

let tutorial resolver source =
  let target = Resolver.Target.tutorial resolver ~source in
  let open Task in
  let prepare =
    let+ () = track_binary
    and+ meta, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Tutorial.Read) source
    in
    Tutorial.make meta content
  in
  Action.Static.write_file_with_metadata
    target
    (prepare
     |> Tutorial.to_document ~source resolver
     >>> Util.Template.chain
           (module Tutorial.Html)
           resolver
           [ "tutorial-content"; "tutorial-layout" ])
;;

let tutorials resolver =
  Batch.iter_files (Resolver.Source.tutorial resolver) (tutorial resolver)
;;

let run ~resolver () =
  let open Eff in
  let cache_file = Resolver.Cache.global resolver in
  Action.restore_cache cache_file
  >>= css resolver
  >>= tutorials resolver
  >>= Action.store_cache cache_file
;;
