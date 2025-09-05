let chain resolver templates =
  Yocaml.Pipeline.read_templates
    (module Yocaml_jingoo)
    ~snapshot:true
    (List.map (Resolver.Source.template resolver) templates)
;;
