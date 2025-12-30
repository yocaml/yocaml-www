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
