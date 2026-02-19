
  do ->

    { object-constructor-name } = dependency 'prelude.Object'
    { value-typetag } = dependency 'prelude.TypeTag'
    { is-string } = dependency 'prelude.Type'

    constructor-name-or-typetag = (value, typetag) ->

      object-constructor-name value

        return if .. isnt void then .. else typetag

    value-typename = (value) ->

      typetag = value-typetag value

      switch typetag

        | 'Object' => constructor-name-or-typetag value, typetag
        | 'Error' => value.name

        else typetag

    value-has-typename = (value, typename) ->

      return null unless is-string typename
      (value-typename value) is typename

    {
      value-typename, value-has-typename
    }