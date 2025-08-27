module Tutorial = Archetype.Tutorial
module Sidebar = Archetype.Sidebar
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

let tutorial_sidebar resolver =
  let open Task in
  let compute_source =
    Path.relocate ~into:(Resolver.Source.tutorial resolver)
  in
  let compute_target source =
    Resolver.Target.tutorial resolver ~source
    |> Resolver.Server.from_target resolver
  in
  let target = Path.(Resolver.Cache.Sidebar.tutorial resolver / "list.sexp") in
  let prepare =
    let source = Path.(Resolver.Source.tutorial resolver / "sidebar.yml") in
    let+ () = track_binary
    and+ () = Pipeline.track_file (Resolver.Source.tutorial resolver)
    and+ sidebar =
      Yocaml_yaml.Pipeline.read_file_as_metadata (module Sidebar.Read) source
    in
    sidebar
  in
  Action.Static.write_file
    target
    (prepare
     >>> Sidebar.resolve
           (module Tutorial.Read)
           ~compute_source
           ~compute_target
           ~synthetize:Tutorial.Read.synthetize
     >>| Sidebar.dump)
;;

let tutorial resolver source =
  let file_target = Resolver.Target.tutorial resolver ~source in
  let target = Resolver.Server.from_target resolver file_target in
  let open Task in
  let prepare =
    let+ () = track_binary
    and+ sidebar =
      Pipeline.read_file_as_metadata
        (module Yocaml.Sexp.Provider)
        (module Sidebar)
        ~snapshot:true
        Path.(Resolver.Cache.Sidebar.tutorial resolver / "list.sexp")
    and+ meta, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Tutorial.Read) source
    in
    Tutorial.make ~sidebar meta content
  in
  Action.Static.write_file_with_metadata
    file_target
    (prepare
     |> Tutorial.to_document ~source ~target resolver
     >>> Util.Template.chain
           (module Tutorial.Html)
           resolver
           [ "tutorial-content"; "tutorial-layout"; "layout" ])
;;

let tutorials resolver =
  Batch.iter_files
    ~where:(Path.has_extension "md")
    (Resolver.Source.tutorial resolver)
    (tutorial resolver)
;;

let run ~resolver () =
  let open Eff in
  let cache_file = Resolver.Cache.global resolver in
  Action.restore_cache cache_file
  >>= css resolver
  >>= tutorial_sidebar resolver
  >>= tutorials resolver
  >>= Action.store_cache cache_file
;;
