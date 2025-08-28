module Path = Yocaml.Path

let default_port = 8888
let default_target = Path.rel [ "_www" ]
let default_cache = Path.rel [ "_cache" ]

module Cmd = struct
  open Cmdliner

  let docs = Manpage.s_common_options
  let exits = Cmd.Exit.defaults
  let version = "dev"

  let path_conv =
    Arg.conv
      ~docv:"PATH"
      ((fun str -> str |> Yocaml.Path.from_string |> Result.ok), Yocaml.Path.pp)
  ;;

  let target_arg =
    let doc = "target directory" in
    let arg = Arg.info ~doc ~docs [ "target"; "output" ] in
    Arg.(value @@ opt path_conv default_target arg)
  ;;

  let cache_arg =
    let doc = "cache directory" in
    let arg = Arg.info ~doc ~docs [ "cache" ] in
    Arg.(value @@ opt path_conv default_cache arg)
  ;;

  let port_arg =
    let doc = "The port for the server  (default: [%d])." in
    let arg = Arg.info ~doc ~docs [ "port"; "P" ] in
    Arg.(value @@ opt int default_port arg)
  ;;

  let build =
    let doc = "Build the website" in
    let info = Cmd.info "build" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder ->
          let resolver = Lib.Resolver.make ~cache_folder ~target_folder () in
          Yocaml_unix.run
            ~level:`Debug
            (Lib.Env.handle resolver (Lib.Rule.run ~resolver)))
        $ target_arg
        $ cache_arg)
    in
    Cmd.v info term
  ;;

  let watch =
    let doc = "Launch a local server" in
    let info = Cmd.info "watch" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder port ->
          let resolver = Lib.Resolver.make ~cache_folder ~target_folder () in
          Yocaml_unix.serve
            ~target:target_folder
            ~level:`Info
            ~port
            (Lib.Env.handle resolver (Lib.Rule.run ~resolver)))
        $ target_arg
        $ cache_arg
        $ port_arg)
    in
    Cmd.v info term
  ;;

  let index =
    let doc = "YOCaml Site Generator" in
    let info = Cmd.info Sys.argv.(0) ~version ~doc ~sdocs:docs ~exits in
    let default = Term.(ret @@ const (`Help (`Pager, None))) in
    Cmd.group info ~default [ build; watch ]
  ;;
end

let () =
  let header = Logs_fmt.pp_header in
  let () = Fmt_tty.setup_std_outputs () in
  let () = Logs.set_reporter Logs_fmt.(reporter ~pp_header:header ()) in
  let () = Logs.set_level (Some Logs.Debug) in
  exit @@ Cmdliner.Cmd.eval Cmd.index
;;
