open Lib.Model
open Test_util

let of_string v =
  v
  |> Yocaml.Data.string
  |> Version.validate
  |> Result.map Version.normalize
  |> validation
;;

let%expect_test "validating version - 1" =
  of_string "1.0.0";
  [%expect
    {|
    [VALID] {"major": 1, "minor": 0, "patch": 0, "identifier": null,
            "has_identifier": false, "repr": "1.0.0", "repr_v": "v1.0.0"}
    |}]
;;

let%expect_test "validating version - 2" =
  of_string "1.3.6";
  [%expect
    {|
    [VALID] {"major": 1, "minor": 3, "patch": 6, "identifier": null,
            "has_identifier": false, "repr": "1.3.6", "repr_v": "v1.3.6"}
    |}]
;;

let%expect_test "validating version - 3" =
  of_string "1.2.3-rc.1";
  [%expect
    {|
    [VALID] {"major": 1, "minor": 2, "patch": 3, "identifier": "rc.1",
            "has_identifier": true, "repr": "1.2.3-rc.1", "repr_v":
             "v1.2.3-rc.1"}
    |}]
;;

let%expect_test "validating version - 4" =
  of_string "1.2.3-rc.1-foo-bar";
  [%expect
    {|
    [VALID] {"major": 1, "minor": 2, "patch": 3, "identifier": "rc.1-foo-bar",
            "has_identifier": true, "repr": "1.2.3-rc.1-foo-bar", "repr_v":
             "v1.2.3-rc.1-foo-bar"}
    |}]
;;
