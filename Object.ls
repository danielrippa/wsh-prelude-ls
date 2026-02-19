
  do ->

    { is-object, is-function } = dependency 'prelude.Type'
    { is-array } = dependency 'prelude.TypeTag'

    object-member-names = (object) ->

      return null unless is-object object
      [ member-name for member-name of object ]

    object-member-values = (object) ->

      return null unless is-object object
      [ member-value for member-name, member-value of object ]

    constructor-name-start-and-end = (constructor-string) -> [ (constructor-string.index-of char) for char in [ ' ', '(' ] ]

    object-constructor-name = (object) ->

      return null unless is-object object

      [ constructor ] = object ; return null unless is-function constructor

      constructor.to-string!

        [ start, end ] = constructor-name-start-and-end ..

        return ..slice start + 1, end

    {
      object-member-names, object-member-values,
      object-constructor-name
    }