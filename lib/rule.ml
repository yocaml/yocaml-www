module Tutorial = Archetype.Tutorial
module Sidebar = Archetype.Sidebar
open Yocaml

let track_binary = Pipeline.track_file Resolver.binary

let css resolver =
  let target = Resolver.Target.css_file resolver in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ content =
      Pipeline.pipe_files
        ~separator:"\n"
        ([ "fonts"; "reset"; "syntax"; "mixins"; "style" ]
         |> List.map (Resolver.Source.css_file resolver))
    in
    content
  in
  Action.Static.write_file target pipeline
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

let javascript resolver =
  Batch.iter_files
    ~where:(Path.has_extension "js")
    (Resolver.Source.javascript resolver)
    (Action.copy_file ~into:(Resolver.Target.javascript resolver))
;;

let materials resolver =
  Batch.iter_files
    (Resolver.Source.materials resolver)
    (Action.copy_file ~into:(Resolver.Target.materials resolver))
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
  let pipeline =
    let+ () = track_binary
    and+ configuration = Env.configuration resolver
    and+ sidebar =
      Pipeline.read_file_as_metadata
        (module Yocaml.Sexp.Provider)
        (module Sidebar)
        ~snapshot:true
        (Resolver.Cache.Sidebar.tutorial resolver)
    and+ templates =
      Util.Template.chain
        resolver
        [ "tutorial-content"; "tutorial-layout"; "layout" ]
    and+ meta, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Tutorial.Read) source
    in
    let meta, content = Tutorial.make ~sidebar ~source meta content in
    let document = Tutorial.as_document ~source ~configuration ~target meta in
    content |> templates (module Tutorial.Html) ~metadata:document
  in
  Action.Static.write_file file_target pipeline
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
  Action.restore_cache ~on:`Source cache_file
  >>= fonts resolver
  >>= images resolver
  >>= css resolver
  >>= javascript resolver
  >>= materials resolver
  >>= tutorial_sidebar resolver
  >>= tutorials resolver
  >>= Action.store_cache ~on:`Source cache_file
;;
