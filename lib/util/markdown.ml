let tm =
  let t = TmLanguage.create () in
  let () =
    [ Hilite.Grammars.ocaml
    ; Hilite.Grammars.ocaml_interface
    ; Hilite.Grammars.dune
    ; Hilite.Grammars.opam
    ; Hilite.Grammars.diff
    ; Yocaml_grammars.Html.value
    ; Yocaml_grammars.Shell.value
    ]
    |> List.iter (fun g ->
      g |> TmLanguage.of_yojson_exn |> TmLanguage.add_grammar t)
  in
  t
;;

let of_string ?(strict = false) content =
  content |> Cmarkit.Doc.of_string ~heading_auto_ids:true ~strict
;;

let to_html ?(safe = false) content =
  content
  |> Hilite_markdown.transform ~skip_unknown_languages:true ~tm
  |> Cmarkit_html.of_doc ~safe
;;

let table_of_content = Yocaml_cmarkit.extract_toc

let on_string ?strict ?safe content =
  content |> of_string ?strict |> to_html ?safe
;;
