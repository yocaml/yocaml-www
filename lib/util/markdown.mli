val of_string : ?strict:bool -> string -> Cmarkit.Doc.t
val to_html : ?safe:bool -> Cmarkit.Doc.t -> string
val table_of_content : Cmarkit.Doc.t -> string option
val on_string : ?strict:bool -> ?safe:bool -> string -> string
