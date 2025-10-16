module Path = Yocaml.Path

let default_port = 8888
let default_target = Path.rel [ "_www" ]
let default_cache = Path.rel [ "_cache" ]
let default_author = "xhtmlboi", "xhtmlboi@gmail.com"
let default_message = "Request Deployment"

let remote_git_repository =
  Format.asprintf "git@github.com-%s:yocaml/yocaml.github.io.git"
;;

module Repo = Yocaml_git.From_identity (Yocaml_unix.Runtime)

let run ~target_folder ~cache_folder =
  let resolver = Lib.Resolver.make ~cache_folder ~target_folder () in
  Lib.Env.handle resolver (Lib.Rule.run ~resolver)
;;

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

  let author_conv =
    let parser value =
      value
      |> Yocaml.Data.string
      |> Lib.Model.Profile.validate
      |> function
      | Ok profile ->
        (match Lib.Model.Profile.email profile with
         | None -> Error (`Msg "Missing email")
         | Some email ->
           Ok
             ( Lib.Model.Profile.display_name profile
             , Lib.Model.Email.to_string email ))
      | Error _ -> Error (`Msg "Invalid author")
    and printer ppf (dname, email) = Format.fprintf ppf "%s <%s>" dname email in
    Arg.conv ~docv:"AUTHOR" (parser, printer)
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

  let author_arg =
    let doc = "Author of the deployment" in
    let arg = Arg.info ~doc ~docs [ "author"; "A" ] in
    Arg.(value @@ opt author_conv default_author arg)
  ;;

  let message_arg =
    let doc = "The commit message attached to the deployment" in
    let arg = Arg.info ~doc ~docs [ "message"; "M" ] in
    Arg.(value @@ opt string default_message arg)
  ;;

  let build =
    let doc = "Build the website" in
    let info = Cmd.info "build" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder ->
          Yocaml_unix.run ~level:`Debug (run ~target_folder ~cache_folder))
        $ target_arg
        $ cache_arg)
    in
    Cmd.v info term
  ;;

  let deploy =
    let doc = "Deploy the site on a Git-repo" in
    let info = Cmd.info "deploy" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun cache_folder (author, email) message ->
          let remote = remote_git_repository author in
          Yocaml_git.run
            (module Repo)
            ~level:`Debug
            ~context:`SSH
            ~author
            ~email
            ~message
            ~remote
            (run ~target_folder:(Path.rel []) ~cache_folder)
          |> Lwt_main.run
          |> Result.iter_error (fun (`Msg err) -> invalid_arg err))
        $ cache_arg
        $ author_arg
        $ message_arg)
    in
    Cmd.v info term
  ;;

  let watch =
    let doc = "Launch a local server" in
    let info = Cmd.info "watch" ~version ~doc ~exits in
    let term =
      Term.(
        const (fun target_folder cache_folder port ->
          Yocaml_unix.serve
            ~target:target_folder
            ~level:`Info
            ~port
            (run ~target_folder ~cache_folder))
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
    Cmd.group info ~default [ build; watch; deploy ]
  ;;
end

let () =
  let header = Logs_fmt.pp_header in
  let () = Fmt_tty.setup_std_outputs () in
  let () = Logs.set_reporter Logs_fmt.(reporter ~pp_header:header ()) in
  let () = Logs.set_level (Some Logs.Debug) in
  exit @@ Cmdliner.Cmd.eval Cmd.index
;;
