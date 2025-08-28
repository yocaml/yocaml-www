open Js_of_ocaml

let element_with_id node =
  Option.bind
    (node |> Dom_html.CoerceTo.element |> Js.Opt.to_option)
    (fun element ->
       element##getAttribute (Js.string "id")
       |> Js.Opt.to_option
       |> Option.map (fun i -> element, Js.to_string i))
;;

let query_selector container selector =
  Js.Opt.bind
    (container##querySelector (Js.string selector))
    Dom_html.CoerceTo.element
  |> Js.Opt.to_option
;;

let query_selector_all container selector =
  container##querySelectorAll (Js.string selector)
  |> Dom.list_of_nodeList
  |> List.filter_map (fun x ->
    x |> Dom_html.CoerceTo.element |> Js.Opt.to_option)
;;

let table_of_content_observer () =
  let open IntersectionObserver in
  let options = empty_intersection_observer_options () in
  let callback entries _observer =
    entries
    |> Js.to_array
    |> Array.iter (fun (entry : intersectionObserverEntry Js.t) ->
      let ( let* ) = Option.bind
      and ( let+ ) x f = Option.map f x in
      let result =
        let* _, id = element_with_id entry##.target in
        let klass = Js.string "toc-entry-active" in
        let ratio = entry##.intersectionRatio |> Js.to_float in
        let selector = "nav#active-toc li a[href='#" ^ id ^ "']" in
        let+ target = query_selector Dom_html.document selector in
        Float.compare ratio 0.0 > 0, target, klass
      in
      match result with
      | Some (flag, target, klass) ->
        if flag
        then target##.classList##add klass
        else target##.classList##remove klass
      | None -> ())
  in
  new%js intersectionObserver (Js.wrap_callback callback) options
;;

let () =
  let observer = table_of_content_observer () in
  [ "h1"; "h2"; "h3"; "h4"; "h5"; "h6" ]
  |> List.map (fun x -> "article.prose " ^ x ^ "[id]")
  |> String.concat ", "
  |> query_selector_all Dom_html.document
  |> List.iter (fun element -> observer##observe element)
;;
