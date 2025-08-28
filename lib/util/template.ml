let chain
      (type a)
      (module T : Yocaml.Required.DATA_INJECTABLE with type t = a)
      resolver
      templates
  =
  Yocaml.Pipeline.chain_templates
    (module Yocaml_jingoo)
    (module T)
    ~snapshot:true
    (List.map (Resolver.Source.template resolver) templates)
;;
