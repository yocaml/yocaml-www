open Lib.Model
open Util

let of_string url = url |> Yocaml.Data.string |> Url.validate

let%expect_test "validating url - 1" =
  let result =
    let+ url = of_string "https://gr-im.github.io" in
    Url.normalize url
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io", "scheme": "https", "host":
             "gr-im.github.io", "path": "/", "port": null, "query": [],
            "query_string": null, "has_port": false, "has_query_string": false}
    |}]
;;

let%expect_test "validating url - 2" =
  let result =
    let+ url = of_string "https://gr-im.github.io/foo/bar?a=b&foo=bar" in
    Url.normalize url
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar?a=b&foo=bar", "scheme":
             "https", "host": "gr-im.github.io", "path": "/foo/bar", "port":
             null, "query":
             [{"fst": "a", "snd": ["b"]}, {"fst": "foo", "snd": ["bar"]}],
            "query_string": "a=b&foo=bar", "has_port": false, "has_query_string":
             true}
    |}]
;;

let%expect_test "validating url - 3" =
  let result =
    let+ url = of_string "https://gr-im.github.io:8080/foo/bar?a=b&foo=bar" in
    Url.normalize url
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io:8080/foo/bar?a=b&foo=bar",
            "scheme": "https", "host": "gr-im.github.io", "path": "/foo/bar",
            "port": 8080, "query":
             [{"fst": "a", "snd": ["b"]}, {"fst": "foo", "snd": ["bar"]}],
            "query_string": "a=b&foo=bar", "has_port": true, "has_query_string":
             true}
    |}]
;;

let%expect_test "Resolve url - 1" =
  let result =
    let+ url = of_string "https://gr-im.github.io" in
    Url.normalize (Url.resolve url Yocaml.Path.(rel [ "foo"; "bar" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar", "scheme": "https",
            "host": "gr-im.github.io", "path": "/foo/bar", "port": null, "query":
             [], "query_string": null, "has_port": false, "has_query_string":
             false}
    |}]
;;

let%expect_test "Resolve url - 2" =
  let result =
    let+ url = of_string "https://gr-im.github.io?foo=bar" in
    Url.normalize (Url.resolve url Yocaml.Path.(rel [ "foo"; "bar" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar", "scheme": "https",
            "host": "gr-im.github.io", "path": "/foo/bar", "port": null, "query":
             [], "query_string": null, "has_port": false, "has_query_string":
             false}
    |}]
;;

let%expect_test "Resolve url - 3" =
  let result =
    let+ url = of_string "https://gr-im.github.io?foo=bar" in
    Url.normalize
      (Url.resolve ~on_query:`Keep url Yocaml.Path.(rel [ "foo"; "bar" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar?foo=bar", "scheme":
             "https", "host": "gr-im.github.io", "path": "/foo/bar", "port":
             null, "query": [{"fst": "foo", "snd": ["bar"]}], "query_string":
             "foo=bar", "has_port": false, "has_query_string": true}
    |}]
;;

let%expect_test "Resolve url - 4" =
  let result =
    let+ url = of_string "https://gr-im.github.io?foo=bar" in
    Url.normalize
      (Url.resolve
         ~on_query:(`Set [ "lang", [ "ocaml"; "rocq" ] ])
         url
         Yocaml.Path.(rel [ "foo"; "bar" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar?lang=ocaml,rocq",
            "scheme": "https", "host": "gr-im.github.io", "path": "/foo/bar",
            "port": null, "query": [{"fst": "lang", "snd": ["ocaml", "rocq"]}],
            "query_string": "lang=ocaml,rocq", "has_port": false,
            "has_query_string": true}
    |}]
;;

let%expect_test "Resolve url - 5" =
  let result =
    let+ url = of_string "https://gr-im.github.io/foo/bar" in
    Url.normalize (Url.resolve url Yocaml.Path.(rel [ "baz" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/foo/bar/baz", "scheme": "https",
            "host": "gr-im.github.io", "path": "/foo/bar/baz", "port": null,
            "query": [], "query_string": null, "has_port": false,
            "has_query_string": false}
    |}]
;;

let%expect_test "Resolve url - 6" =
  let result =
    let+ url = of_string "https://gr-im.github.io/foo/bar" in
    Url.normalize (Url.resolve url Yocaml.Path.(abs [ "baz" ]))
  in
  validation Yocaml.Data.pp result;
  [%expect
    {|
    [VALID] {"target": "https://gr-im.github.io/baz", "scheme": "https", "host":
             "gr-im.github.io", "path": "/baz", "port": null, "query": [],
            "query_string": null, "has_port": false, "has_query_string": false}
    |}]
;;

let%expect_test "Direct url creation - 1" =
  let result = "github.com" |> Url.https |> Url.normalize in
  validation Yocaml.Data.pp (Ok result);
  [%expect
    {|
    [VALID] {"target": "https://github.com", "scheme": "https", "host":
             "github.com", "path": "/", "port": null, "query": [],
            "query_string": null, "has_port": false, "has_query_string": false}
    |}]
;;

let%expect_test "Direct url creation - 2" =
  let result = "github.com" |> Url.http |> Url.normalize in
  validation Yocaml.Data.pp (Ok result);
  [%expect
    {|
    [VALID] {"target": "http://github.com", "scheme": "http", "host":
             "github.com", "path": "/", "port": null, "query": [],
            "query_string": null, "has_port": false, "has_query_string": false}
    |}]
;;

let%expect_test "Direct url creation - 3" =
  let result =
    "github.com"
    |> Url.https ~path:Yocaml.Path.(abs [ "gr-im"; "site" ])
    |> Url.normalize
  in
  validation Yocaml.Data.pp (Ok result);
  [%expect
    {|
    [VALID] {"target": "https://github.com/gr-im/site", "scheme": "https",
            "host": "github.com", "path": "/gr-im/site", "port": null, "query":
             [], "query_string": null, "has_port": false, "has_query_string":
             false}
    |}]
;;

let%expect_test "Direct url creation - 4" =
  let result =
    "github.com/gr-im/site"
    |> Url.https ~path:Yocaml.Path.(rel [ "blob"; "index.md" ])
    |> Url.normalize
  in
  validation Yocaml.Data.pp (Ok result);
  [%expect
    {|
    [VALID] {"target": "https://github.com/gr-im/site/blob/index.md", "scheme":
             "https", "host": "github.com", "path": "/gr-im/site/blob/index.md",
            "port": null, "query": [], "query_string": null, "has_port": false,
            "has_query_string": false}
    |}]
;;
