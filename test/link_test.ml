open Lib.Model
open Test_util

let%expect_test "validation from a record - 1" =
  let result =
    let input =
      let open Yocaml.Data in
      record [ "name", string "ocaml"; "url", string "https://ocaml.org" ]
    in
    let+ link = Link.validate input in
    Link.normalize link
  in
  validation result;
  [%expect
    {|
    [VALID] {"name": "ocaml", "url":
             {"target": "https://ocaml.org", "scheme": "https", "host":
              "ocaml.org", "path": "/", "port": null, "query": [],
             "query_string": null, "has_port": false, "has_query_string": false},
            "description": null, "has_description": false}
    |}]
;;

let%expect_test "validation from a record - 2" =
  let result =
    let input =
      let open Yocaml.Data in
      record
        [ "title", string "ocaml"
        ; "url", string "https://ocaml.org"
        ; "alt", string "A description"
        ]
    in
    let+ link = Link.validate input in
    Link.normalize link
  in
  validation result;
  [%expect
    {|
    [VALID] {"name": "ocaml", "url":
             {"target": "https://ocaml.org", "scheme": "https", "host":
              "ocaml.org", "path": "/", "port": null, "query": [],
             "query_string": null, "has_port": false, "has_query_string": false},
            "description": "A description", "has_description": true}
    |}]
;;

let%expect_test "validation from an url - 1" =
  let result =
    let input = Yocaml.Data.string "https://ocaml.org/foo/bar" in
    let+ link = Link.validate input in
    Link.normalize link
  in
  validation result;
  [%expect
    {|
    [VALID] {"name": "ocaml.org/foo/bar", "url":
             {"target": "https://ocaml.org/foo/bar", "scheme": "https", "host":
              "ocaml.org", "path": "/foo/bar", "port": null, "query": [],
             "query_string": null, "has_port": false, "has_query_string": false},
            "description": null, "has_description": false}
    |}]
;;
