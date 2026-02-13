(lang dune 3.20)
(name yocaml-www)
(version dev)
(generate_opam_files)
(using mdx 0.4)

(source (github yocaml/yocaml-www))
(license GPL-3.0-or-later)
(authors
  "gr-im <grimfw@gmail.com>"
  "The XHTMLBoy <xhtmlboi@gmail.com>"
  "xvw <xaviervdw@gmail.com>"
  "msp <spanwmick@gmail.com>")
(maintainers
  "gr-im <grimfw@gmail.com>"
  "The XHTMLBoy <xhtmlboi@gmail.com>"
  "xvw <xaviervdw@gmail.com>"
  "msp <spanwmick@gmail.com>")

(package
 (name yocaml-www)
 (synopsis "The YOCaml website")
 (description "Source code of the YOCaml website")
 (depends
  (ocaml (>= 5.3.0))

   ;; YOCaml dependencies
   (yocaml (>= 3.0.0))
   (yocaml_runtime (>= 3.0.0) )
   (yocaml_unix (>= 3.0.0))
   (yocaml_git (>= 3.0.0))
   (yocaml_syndication (>= 3.0.0))
   (yocaml_yaml (>= 3.0.0))
   (yocaml_otoml (>= 3.0.0))
   (yocaml_jingoo (>= 3.0.0))
   (yocaml_markdown (>= 3.0.0))

   ;; Additional dependencies
   yojson
   uri
   emile
   mdx
  (cmdliner (>= 1.3.0))
  (cmarkit (>= 0.3.0))
  (hilite (>= 0.5.0))

   ;; Js of OCaml
   js_of_ocaml-compiler
   js_of_ocaml-ppx

  ;; Test setup
  (ppx_expect :with-test)
   
  ;; dev setup
  (utop :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (merlin :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)))
