open Lib.Model
open Test_util

let%expect_test "validation - 1" =
  let result =
    let input =
      let open Yocaml.Data in
      record
        [ "forge", string "github"
        ; "user", string "gr-im"
        ; "repo", string "site"
        ]
    in
    let+ repo = Repository.validate input in
    Repository.normalize repo
  in
  validation result;
  [%expect
    {|
    [VALID] {"forge":
             {"name": "github", "url":
              {"target": "https://github.com", "scheme": "https", "host":
               "github.com", "path": "/", "port": null, "query": [],
              "query_string": null, "has_port": false, "has_query_string": false},
             "domain": "github.com"},
            "ident": "gr-im/site", "compononent": ["gr-im", "site"], "homepage":
             {"target": "https://github.com/gr-im/site", "scheme": "https",
             "host": "github.com", "path": "/gr-im/site", "port": null, "query":
              [], "query_string": null, "has_port": false, "has_query_string":
              false},
            "slug": "https-github-com-gr-im-site", "bug_tracker":
             {"target": "https://github.com/gr-im/site/issues", "scheme":
              "https", "host": "github.com", "path": "/gr-im/site/issues",
             "port": null, "query": [], "query_string": null, "has_port": false,
             "has_query_string": false},
            "clone":
             {"ssh": "git@github.com:gr-im/site.git", "https":
              "https://github.com/gr-im/site.git"}}
    |}]
;;

let%expect_test "validation using a compact version - 1" =
  let result =
    let input =
      let open Yocaml.Data in
      string "gh/gr-im/site"
    in
    let+ repo = Repository.validate input in
    Repository.normalize repo
  in
  validation result;
  [%expect
    {|
    [VALID] {"forge":
             {"name": "github", "url":
              {"target": "https://github.com", "scheme": "https", "host":
               "github.com", "path": "/", "port": null, "query": [],
              "query_string": null, "has_port": false, "has_query_string": false},
             "domain": "github.com"},
            "ident": "gr-im/site", "compononent": ["gr-im", "site"], "homepage":
             {"target": "https://github.com/gr-im/site", "scheme": "https",
             "host": "github.com", "path": "/gr-im/site", "port": null, "query":
              [], "query_string": null, "has_port": false, "has_query_string":
              false},
            "slug": "https-github-com-gr-im-site", "bug_tracker":
             {"target": "https://github.com/gr-im/site/issues", "scheme":
              "https", "host": "github.com", "path": "/gr-im/site/issues",
             "port": null, "query": [], "query_string": null, "has_port": false,
             "has_query_string": false},
            "clone":
             {"ssh": "git@github.com:gr-im/site.git", "https":
              "https://github.com/gr-im/site.git"}}
    |}]
;;
