let string_not_blank =
  let open Yocaml.Data.Validation in
  Result.ok $ String.trim
  & where
      ~pp:Format.pp_print_string
      ~message:(fun _ -> "Can't be blank")
      (fun s -> not (String.equal "" s))
;;

let not_blank =
  let open Yocaml.Data.Validation in
  string & string_not_blank
;;

let tokenize x = x |> String.trim |> String.lowercase_ascii

let remove_first_char_when pred string =
  match
    try Some (Stdlib.String.get string 0) with
    | Invalid_argument _ -> None
  with
  | Some c ->
    if pred c
    then (
      let len = Stdlib.String.length string in
      Stdlib.String.sub string 1 (len - 1))
    else string
  | None -> string
;;

let remove_arobase = remove_first_char_when (Char.equal '@')
let remove_dot = remove_first_char_when (Char.equal '.')
let remove_hash = remove_first_char_when (Char.equal '#')
