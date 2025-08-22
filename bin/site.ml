let program () =
  let open Yocaml.Eff in
  let* () = log "Hello World" in
  let* _c = Lib.Env.get_configuration () in
  let* _c = Lib.Env.get_configuration () in
  let* () = log "Step 1" in
  let* _c = Lib.Env.get_configuration () in
  log "Done"
;;

let () =
  let log_level = `Debug in
  let configuration_path = Yocaml.Path.rel [ "configuration.toml" ] in
  let () = Yocaml_runtime.Log.setup ~level:log_level () in
  Yocaml_unix.run ~level:log_level (Lib.Env.handle ~configuration_path program)
;;
