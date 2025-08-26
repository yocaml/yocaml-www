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
  let resolver = Lib.Resolver.make () in
  let log_level = `Debug in
  let () = Yocaml_runtime.Log.setup ~level:log_level () in
  Yocaml_unix.run ~level:log_level (Lib.Env.handle resolver program)
;;
