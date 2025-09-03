open Js_of_ocaml

module Util = struct
  let query_selector container selector =
    Js.Opt.bind
      (container##querySelector (Js.string selector))
      Dom_html.CoerceTo.element
  ;;

  let query_selector_all container selector =
    container##querySelectorAll (Js.string selector)
    |> Dom.list_of_nodeList
    |> List.filter_map (fun x ->
      x |> Dom_html.CoerceTo.element |> Js.Opt.to_option)
  ;;

  let add_class elt klass = elt##.classList##add klass
  let remove_class elt klass = elt##.classList##remove klass
end

module Active_toc = struct
  let ( let* ) = Js.Opt.bind
  let ( let+ ) = Js.Opt.map

  let observer () =
    let open IntersectionObserver in
    let options = empty_intersection_observer_options () in
    let callback entries _observer =
      entries
      |> Js.to_array
      |> Array.iter (fun (entry : intersectionObserverEntry Js.t) ->
        let result =
          let* el = entry##.target |> Dom_html.CoerceTo.element in
          let* id = el##getAttribute (Js.string "id") in
          let id = Js.to_string id in
          let ratio = entry##.intersectionRatio |> Js.to_float in
          let selector = "nav#active-toc li a[href='#" ^ id ^ "']" in
          let+ target = Util.query_selector Dom_html.document selector in
          Float.compare ratio 0.0 > 0, target, id
        in
        Js.Opt.iter result (fun (flag, target, _id) ->
          let klass = Js.string "toc-entry-active" in
          if flag
          then Util.add_class target klass
          else Util.remove_class target klass))
    in
    new%js intersectionObserver (Js.wrap_callback callback) options
  ;;

  let run () =
    match Dom_html.getElementById_opt "active-toc" with
    | Some _ ->
      let observer = observer () in
      [ "h1"; "h2"; "h3"; "h4"; "h5"; "h6" ]
      |> List.map (fun x -> "article.prose " ^ x ^ "[id]")
      |> String.concat ", "
      |> Util.query_selector_all Dom_html.document
      |> List.iter (fun element -> observer##observe element)
    | None -> ()
  ;;
end

let () = Active_toc.run ()
