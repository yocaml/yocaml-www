type _ Effect.t += Yocaml_www_get_config : Model.Configuration.t Effect.t

let get_configuration () = Yocaml.Eff.perform @@ Yocaml_www_get_config

let read_configuration configuration_path =
  let open Yocaml.Eff in
  function
  | Some configuration ->
    let+ () = logf "Configuration already read" in
    configuration
  | None ->
    let* () =
      logf "Read configuration from [%a]" Yocaml.Path.pp configuration_path
    in
    Yocaml_otoml.Eff.read_file_as_metadata
      (module Model.Configuration)
      ~on:`Source
      configuration_path
;;

let handle ~configuration_path program input =
  let config : Model.Configuration.t option ref = ref None in
  let handler () =
    match program input with
    | x -> x
    | effect Yocaml_www_get_config, k ->
      let open Yocaml.Eff in
      let* result = read_configuration configuration_path !config in
      let () = config := Some result in
      Effect.Deep.continue k result
  in
  handler ()
;;

let configuration path =
  Yocaml.Task.make
    ~has_dynamic_dependencies:false
    (Yocaml.Deps.singleton path)
    get_configuration
;;
