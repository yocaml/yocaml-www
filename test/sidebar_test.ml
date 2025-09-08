open Yocaml.Path
open Lib.Archetype.Sidebar

let print_focus ~source sidebar =
  let prev, next = get_focus ~source sidebar in
  let pp_ref = Format.pp_print_option Yocaml.Data.pp in
  Format.asprintf
    "%a @. <- %a -> @. %a"
    pp_ref
    (Option.map Reference.normalize prev)
    Yocaml.Path.pp
    source
    pp_ref
    (Option.map Reference.normalize next)
  |> print_endline
;;

let e ?(to_be_done = false) source =
  let sname = to_string source in
  entry
    ~source
    ~target:(relocate ~into:(abs [ "www" ]) source)
    ~name:("Entry " ^ sname)
    ~to_be_done
    ~description:("Description of " ^ sname)
;;

let%expect_test
    "There is no predecessor and successor because the sidebar is empty"
  =
  let source = rel [ "a.md" ]
  and sidebar = of_list [] in
  print_focus ~source sidebar;
  [%expect {| <- ./a.md -> |}]
;;

let%expect_test
    "There is no predecessor and successor because the sidebar has one element"
  =
  let source = rel [ "a.md" ] in
  let sidebar = of_list [ "first-section", [ e source ] ] in
  print_focus ~source sidebar;
  [%expect {| <- ./a.md -> |}]
;;

let%expect_test "There is a successor" =
  let source = rel [ "a.md" ] in
  let sidebar =
    of_list [ "first-section", [ e source; e @@ rel [ "b.md" ] ] ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    <- ./a.md ->
    {"title": "first-section", "name": "Entry ./b.md", "description":
     "Description of ./b.md", "target": "/www/b.md"}
    |}]
;;

let%expect_test "There is both successor and pred" =
  let source = rel [ "b.md" ] in
  let sidebar =
    of_list
      [ "first-section", [ e @@ rel [ "a.md" ]; e source; e @@ rel [ "c.md" ] ]
      ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    {"title": "first-section", "name": "Entry ./a.md", "description":
     "Description of ./a.md", "target": "/www/a.md"}
     <- ./b.md ->
     {"title": "first-section", "name": "Entry ./c.md", "description":
      "Description of ./c.md", "target": "/www/c.md"}
    |}]
;;

let%expect_test "There is both successor and pred in different section" =
  let source = rel [ "b.md" ] in
  let sidebar =
    of_list
      [ "first-section", [ e @@ rel [ "a.md" ] ]
      ; "second-section", [ e source; e @@ rel [ "c.md" ] ]
      ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    {"title": "first-section", "name": "Entry ./a.md", "description":
     "Description of ./a.md", "target": "/www/a.md"}
     <- ./b.md ->
     {"title": "second-section", "name": "Entry ./c.md", "description":
      "Description of ./c.md", "target": "/www/c.md"}
    |}]
;;

let%expect_test "There is both successor and pred in different section" =
  let source = rel [ "b.md" ] in
  let sidebar =
    of_list
      [ "first-section", [ e @@ rel [ "a.md" ] ]
      ; "second-section", [ e source ]
      ; "third-section", [ e @@ rel [ "c.md" ] ]
      ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    {"title": "first-section", "name": "Entry ./a.md", "description":
     "Description of ./a.md", "target": "/www/a.md"}
     <- ./b.md ->
     {"title": "third-section", "name": "Entry ./c.md", "description":
      "Description of ./c.md", "target": "/www/c.md"}
    |}]
;;

let%expect_test "There is both successor and pred in different section" =
  let source = rel [ "c.md" ] in
  let sidebar =
    of_list
      [ "first-section", [ e @@ rel [ "a.md" ] ]
      ; "second-section", [ e @@ rel [ "b.md" ] ]
      ; "third-section", [ e @@ rel [ "c.md" ] ]
      ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    {"title": "second-section", "name": "Entry ./b.md", "description":
     "Description of ./b.md", "target": "/www/b.md"}
     <- ./c.md ->
    |}]
;;

let%expect_test
    "There is both successor and pred in different section with an empty \
     section"
  =
  let source = rel [ "b.md" ] in
  let sidebar =
    of_list
      [ "first-section", [ e @@ rel [ "a.md" ] ]
      ; "second-section", [ e @@ rel [ "b.md" ] ]
      ; "phantom-section", []
      ; "third-section", [ e @@ rel [ "c.md" ] ]
      ]
  in
  print_focus ~source sidebar;
  [%expect
    {|
    {"title": "first-section", "name": "Entry ./a.md", "description":
     "Description of ./a.md", "target": "/www/a.md"}
     <- ./b.md ->
     {"title": "third-section", "name": "Entry ./c.md", "description":
      "Description of ./c.md", "target": "/www/c.md"}
    |}]
;;
