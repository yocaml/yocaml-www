let () =
  let resolver = Lib.Resolver.make () in
  let log_level = `Debug in
  let () = Yocaml_runtime.Log.setup ~level:log_level () in
  Yocaml_unix.run
    ~level:log_level
    (Lib.Env.handle resolver (Lib.Rule.run ~resolver))
;;
