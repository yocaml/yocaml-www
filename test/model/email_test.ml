open Lib.Model
open Test_util

let of_string email =
  email |> Yocaml.Data.string |> Email.validate |> Result.map Email.normalize
;;

let%expect_test "validate email - 1" =
  let email = of_string "gr-im@fwkr.com" in
  validation email;
  [%expect
    {|
    [VALID] {"address": "gr-im@fwkr.com", "local": "gr-im", "domain":
             "fwkr.com", "domain_fragments": ["fwkr", "com"], "address_md5":
             "3757998efa8b0a9a35ce6118abb34ebf"}
    |}]
;;

let%expect_test "validate email - 2" =
  let email = of_string "gr-im+twitter@gmail.com" in
  validation email;
  [%expect
    {|
    [VALID] {"address": "gr-im+twitter@gmail.com", "local": "gr-im+twitter",
            "domain": "gmail.com", "domain_fragments": ["gmail", "com"],
            "address_md5": "b1df4f54780302d29a6bffd0b577e520"}
    |}]
;;

let%expect_test "validate email - 3" =
  let email = of_string "gr-im+twittergmail.com" in
  validation email;
  [%expect
    {|
    [INVALID] --- Oh dear, an error has occurred ---
    Validation error: `test`

    Fail with message: { message = `Invalid `gr-im+twittergmail.com``;
                         given = `gr-im+twittergmail.com`;}
    ---
    The backtrace is not available because the function is called (according to the [in_exception_handler] parameter) outside an exception handler. This makes the trace unspecified.
    |}]
;;
