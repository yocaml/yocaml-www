let ( let* ) = Result.bind
let ( let+ ) x f = Result.map f x

let validation = function
  | Error err ->
    (* The ceremony for correctly printing validation errors is a bit
       sad and should be improved in YOCaml. *)
    let open Yocaml in
    let exn =
      Eff.Provider_error
        (Required.Validation_error { entity = "test"; error = err })
    in
    exn
    |> Format.asprintf "[INVALID] %a" (fun ppf x ->
      Diagnostic.exception_to_diagnostic ~in_exception_handler:false ppf x)
    |> print_endline
  | Ok value ->
    value |> Format.asprintf "[VALID] %a" Yocaml.Data.pp |> print_endline
;;
