open Lib.Model
open Test_util

let%expect_test "cover to open graph 1" =
  let result =
    let input = Yocaml.Data.(string "https://google.it/foo.png") in
    let+ c = Cover.validate input in
    c |> Cover.to_open_graph |> Meta_tag.normalize_list
  in
  validation result;
  [%expect
    {| [VALID] [{"name": "og:image", "content": "https://google.it/foo.png"}] |}]
;;

let%expect_test "cover to open graph 2" =
  let result =
    let input =
      Yocaml.Data.(
        record
          [ "kind", string "video"
          ; "url", string "https://google.it/foo.mp4"
          ; "width", int 340
          ; "height", int 120
          ; "alt", string "A video"
          ])
    in
    let+ c = Cover.validate input in
    c |> Cover.to_open_graph |> Meta_tag.normalize_list
  in
  validation result;
  [%expect
    {|
    [VALID] [{"name": "og:video", "content": "https://google.it/foo.mp4"},
            {"name": "og:video:width", "content": "340"},
            {"name": "og:video:height", "content": "120"},
            {"name": "og:video:alt", "content": "A video"}]
    |}]
;;
