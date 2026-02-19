
  do ->

    { value-typetag } = dependency 'prelude.TypeTag'
    { value-typename } = dependency 'prelude.TypeName'
    { punctuation-chars } = dependency 'prelude.Char'
    { angle-brackets, single-quotes, square-brackets, curly-brackets, round-brackets, circumfix } = dependency 'prelude.Circumfix'
    { function-parameter-names } = dependency 'prelude.Function'

    { colon, comma } = punctuation-chars ;

    pad-with-space = circumfix _, [ ' ' ]

    join-with-comma = (* ', ')

    as-collection = (brackets) -> -> it |> join-with-comma |> pad-with-space |> brackets

    as-array = as-collection square-brackets

    as-object = as-collection curly-brackets

    function-as-string = (fn) -> function-parameter-names fn |> join-with-comma |> round-brackets |> -> [ it, '->', curly-brackets '' ] |> (* ' ')

    member-as-string = (member-name, member-value) -> [ member-name, colon, ' ', member-value ] * ''

    array-as-string = (array) ->

      [ (value-as-string item) for item in array ] |> as-array

    object-as-string = (object) ->

      [ (member-as-string member-name, value-as-string object[ member-name ]) for member-name of object ] |> as-object

    value-as-string = (value) ->

      switch value-typetag value

        | 'Void' => 'void'
        | 'Null' => 'null'

        | 'String' => single-quotes value
        | 'Function' => function-as-string value

        | 'Array' => array-as-string value

        | 'Object', 'Error' => object-as-string value

        else "#value"

    typed-array-as-string = (array) ->

      [ (typed-value-as-string item) for item in array ] |> as-array

    typed-object-as-string = (object) ->

      [ (member-as-string member-name, typed-value-as-string object[ member-name ]) for member-name of object ] |> as-object

    typed-value-as-string = (value) ->

      value-string = switch value-typetag value

        | 'Array' => typed-array-as-string value
        | 'Object', 'Error' => typed-object-as-string value

        else value-as-string value

      [ (angle-brackets value-typename value), value-string ] * ' '

    {
      value-as-string, typed-value-as-string
    }
