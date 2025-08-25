module Make (O : Specs.ORDERED_TYPE) = struct
  include Stdlib.Set.Make (O)

  let validate =
    let open Yocaml.Data.Validation in
    list_of O.validate
    / record (fun o ->
      field o.${"elements"} (option @@ list_of O.validate)
      |? field o.${"set"} (option @@ list_of O.validate)
      |? field o.${"elts"} (option @@ list_of O.validate)
      |? field o.${"all"} (option @@ list_of O.validate)
      $? Ok [])
    $ of_list
  ;;

  let normalize set =
    let open Yocaml.Data in
    record
      [ "elements", set |> to_list |> list_of O.normalize
      ; "length", set |> cardinal |> int
      ; "has_elements", bool (not (is_empty set))
      ]
  ;;
end

module String = Make (Ordered.String)
module Path = Make (Ordered.Path)
