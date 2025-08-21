(lang dune 3.19)
(name yocaml-www)
(version dev)
(generate_opam_files)
(executables_implicit_empty_intf)

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
  (yocaml (>= 2.4.0))
  (yocaml_unix (>= 2.4.0))
  (yocaml_syndication (>= 2.4.0))
  (yocaml_yaml (>= 2.4.0))
  (yocaml_otoml (>= 2.4.0))
  (yocaml_jingoo (>= 2.4.0))

  ;; Additional dependencies
  (cmdliner (>= 1.3.0))
  (cmarkit (>= 0.3.0))
  (hilite (>= 0.5.0))

  ;; Test setup
  (ppx_expect :with-test)
   
  ;; dev setup
  (utop :with-dev-setup)
  (ocamlformat :with-dev-setup)
  (ocp-indent :with-dev-setup)
  (merlin :with-dev-setup)
  (ocaml-lsp-server :with-dev-setup)))
