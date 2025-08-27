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
           ([ "fonts"; "reset"; "syntax"; "mixins"; "style" ]
            |> List.map (Resolver.Source.css_file resolver)))
;;

let fonts resolver =
  Batch.iter_files
    ~where:(Path.has_extension "woff2")
    (Resolver.Source.fonts resolver)
    (Action.copy_file ~into:(Resolver.Target.fonts resolver))
;;

let images resolver =
  Batch.iter_files
    (Resolver.Source.images resolver)
    (Action.copy_file ~into:(Resolver.Target.images resolver))
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
  let target = Resolver.Cache.Sidebar.tutorial resolver in
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
        (Resolver.Cache.Sidebar.tutorial resolver)
    and+ meta, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Tutorial.Read) source
    in
    Tutorial.make ~sidebar ~source meta content
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
  >>= fonts resolver
  >>= images resolver
  >>= css resolver
  >>= tutorial_sidebar resolver
  >>= tutorials resolver
  >>= Action.store_cache cache_file
;;
