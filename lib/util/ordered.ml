module String = struct
  include Stdlib.String

  let validate = Yocaml.Data.Validation.string ~strict:false
  let normalize = Yocaml.Data.string
end

module Path = struct
  type t = Yocaml.Path.t

  let compare = Yocaml.Path.compare
  let validate = Yocaml.Data.Validation.path
  let normalize = Yocaml.Data.path
end

module Datetime = struct
  type t = Yocaml.Datetime.t

  let compare = Yocaml.Datetime.compare
  let validate = Yocaml.Datetime.validate
  let normalize = Yocaml.Datetime.normalize
end
