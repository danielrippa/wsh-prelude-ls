do ->

    { is-object, is-function } = dependency 'prelude.reflection.ValueType'
    { value-typetag } = dependency 'prelude.reflection.TypeTag'

    object-constructor-name = (value) ->

      return null unless is-object value

      { constructor } = value ; return null unless is-function constructor

      constructor.to-string!

        start = ..index-of ' ' |> (+ 1)
        end   = ..index-of '('

        return ..slice start, end

    value-typename = (value) ->

      typetag = value-typetag value

      switch typetag

        | 'Object' =>

          constructor-name = object-constructor-name value

          if constructor-name? then constructor-name else typetag

        | 'Error' => value.name

        else typetag

    value-has-typename = (value, typename) -> (value-typename value) is typename

    {
      value-typename,
      value-has-typename
    }