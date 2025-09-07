let tm =
  let t = Yocaml_markdown.Doc.default_grammars_set in
  let () =
    [ Yocaml_grammars.Shell.value
    ; Yocaml_grammars.Html.value
    ; Yocaml_grammars.Markdown.value
    ]
    |> List.iter (fun g ->
      g |> TmLanguage.of_yojson_exn |> TmLanguage.add_grammar t)
  in
  t
;;

let highlight () =
  Yocaml_markdown.Doc.syntax_highlighting ~skip_unknown_languages:true ~tm ()
;;
