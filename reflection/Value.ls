do ->

    { value-typetag } = dependency 'prelude.reflection.TypeTag'
    { value-type } = dependency 'prelude.reflection.ValueType'
    { value-typename } = dependency 'prelude.reflection.TypeName'
    { function-parameter-names } = dependency 'prelude.Function'
    { kebab-case } = dependency 'prelude.String'

    csv = (* ', ')

    square-brackets = -> "[#it]"
    round-brackets  = -> "(#it)"
    curly-brackets  = -> "{#it}"
    angle-brackets = -> "<#it>"

    pad-with-space = -> " #it "

    single-quotes = -> "'#it'"

    map = (array, fn) -> [ (fn item) for item in array ]

    object-member-pairs = (object) -> [ ([ key, value ]) for key, value of object ]

    items-as-string = (array) -> array |> csv |> pad-with-space |> square-brackets

    array-as-string = (array) -> map array, value-as-string |> items-as-string

    parameters-as-string = (fn) ->

      parameters = function-parameter-names fn

      if parameters is '' then '' else round-brackets parameters

    function-as-string = (fn) -> "#{ parameters-as-string fn }->"

    pairs-as-member-string = ([ key, value ]) -> "#{ kebab-case key }: #{ value-as-string value }"

    members-as-string = (members) -> members |> csv |> pad-with-space |> curly-brackets

    object-as-string = (object) -> object |> object-member-pairs |> map _ , pairs-as-member-string |> members-as-string

    typed-array-as-string = (array) -> map array, typed-value-as-string |> items-as-string

    pair-as-typed-member-string = ([ key, value ]) -> "#{ typed-value-as-string kebab-case key }: #{ typed-value-as-string value }"

    typed-object-as-string = (object) -> object |> object-member-pairs |> map _ , pair-as-typed-member-string |> members-as-string

    #

    value-as-string = (value) ->

      switch value-typetag value

        | 'Void' => 'void'
        | 'Null' => 'null'

        | 'String' => single-quotes value
        | 'Array' => array-as-string value
        | 'Function' => function-as-string value

        | 'Object', 'Error', 'RegExp' => object-as-string value

        else "#value"

    #

    typed-value-as-string = (value) ->

      value-string = switch value-typetag value

        | 'Array' => typed-array-as-string value
        | 'Object', 'Error', 'RegExp' => typed-object-as-string value

        else value-as-string value

      type-string = angle-brackets value-typename value

      "#type-string #value-string"

    {
      value-as-string, typed-value-as-string
    }