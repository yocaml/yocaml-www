open Lib

let path p = p |> Format.asprintf "%a" Yocaml.Path.pp |> print_endline

let%expect_test "resolve assets on source" =
  let r = Resolver.make () in
  let x = Resolver.Source.assets r in
  path x;
  [%expect {| ./assets |}]
;;

let%expect_test "resolve css on source" =
  let r = Resolver.make () in
  let x = Resolver.Source.css r in
  path x;
  [%expect {| ./assets/css |}]
;;

let%expect_test "resolve assets on target" =
  let r = Resolver.make () in
  let x = Resolver.Target.assets r in
  path x;
  [%expect {| ./_www/assets |}]
;;

let%expect_test "resolve css on target" =
  let r = Resolver.make () in
  let x = Resolver.Target.css r in
  path x;
  [%expect {| ./_www/assets/css |}]
;;

let%expect_test "resolve css on target with a server root" =
  let server_root = Yocaml.Path.abs [ "blog"; "yocaml"; "grm" ] in
  let r = Resolver.make ~server_root () in
  let x = Resolver.Target.css r in
  path x;
  [%expect {| ./_www/blog/yocaml/grm/assets/css |}]
;;

let%expect_test "resolve assets on server" =
  let r = Resolver.make () in
  let x = Resolver.Server.assets r in
  path x;
  [%expect {| /assets |}]
;;

let%expect_test "resolve css on server" =
  let r = Resolver.make () in
  let x = Resolver.Server.css r in
  path x;
  [%expect {| /assets/css |}]
;;

let%expect_test "test on resolving from target to server in simple case" =
  let target_folder = Yocaml.Path.rel [ "out" ] in
  let resolver = Resolver.make ~target_folder () in
  Yocaml.Path.
    [ rel [ "out" ]
    ; rel [ "out"; "foo.html" ]
    ; rel [ "out"; "foo"; "bar"; "test.html" ]
    ; abs [ "out" ] (* not relative *)
    ; rel [ "foo"; "bar" ]
    ]
  |> List.iter (fun x -> path (Resolver.Server.from_target resolver x));
  [%expect
    {|
    /
    /foo.html
    /foo/bar/test.html
    /out
    /foo/bar
    |}]
;;

let%expect_test "test on resolving from target to server with server root" =
  let target_folder = Yocaml.Path.rel [ "out" ]
  and server_root = Yocaml.Path.abs [ "blog"; "yocaml"; "grm" ] in
  let resolver = Resolver.make ~target_folder ~server_root () in
  Yocaml.Path.
    [ rel [ "out"; "blog"; "yocaml"; "grm" ]
    ; rel [ "out"; "blog"; "yocaml"; "grm"; "foo.html" ]
    ; rel [ "out"; "blog"; "yocaml"; "grm"; "foo"; "bar"; "test.html" ]
    ; abs [ "out"; "blog"; "yocaml"; "grm" ] (* not relative *)
    ; rel [ "foo"; "bar" ]
    ]
  |> List.iter (fun x -> path (Resolver.Server.from_target resolver x));
  [%expect
    {|
    /blog/yocaml/grm
    /blog/yocaml/grm/foo.html
    /blog/yocaml/grm/foo/bar/test.html
    /blog/yocaml/grm/out/blog/yocaml/grm
    /blog/yocaml/grm/foo/bar
    |}]
;;
