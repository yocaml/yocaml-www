module Set (O : Specs.ORDERED_TYPE) = struct
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

module Map (O : Specs.ORDERED_TYPE) = struct
  include Stdlib.Map.Make (O)

  let validate_line on_value =
    let open Yocaml.Data.Validation in
    record (fun o ->
      let+ key =
        field o.${"key"} (option O.validate)
        |? field o.${"k"} (option O.validate)
        |? field o.${"index"} (option O.validate)
        |? field o.${"fst"} (option O.validate)
        |? field o.${"first"} (option O.validate)
        $? field o.${"0"} O.validate
      and+ value =
        field o.${"value"} (option on_value)
        |? field o.${"v"} (option on_value)
        |? field o.${"val"} (option on_value)
        |? field o.${"snd"} (option on_value)
        |? field o.${"second"} (option on_value)
        $? field o.${"1"} on_value
      in
      key, value)
  ;;

  let validate on_value =
    let open Yocaml.Data.Validation in
    list_of (pair O.validate on_value / validate_line on_value)
    / record (fun o ->
      field o.${"elements"} (option @@ list_of (validate_line on_value))
      |? field o.${"map"} (option @@ list_of (validate_line on_value))
      |? field o.${"elts"} (option @@ list_of (validate_line on_value))
      |? field o.${"all"} (option @@ list_of (validate_line on_value))
      $? Ok [])
    $ of_list
  ;;

  let normalize on_value map =
    let open Yocaml.Data in
    record
      [ ( "elements"
        , map
          |> to_list
          |> list_of (fun (k, v) ->
            record [ "key", O.normalize k; "value", on_value v ]) )
      ; "length", map |> cardinal |> int
      ; "has_element", bool (not (is_empty map))
      ]
  ;;
end
