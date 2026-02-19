
  do ->

    { throw-error } = dependency 'prelude.Error'
    { typed-value-as-string } = dependency 'prelude.Value'
    { object-member-names } = dependency 'prelude.Object'
    { array-size } = dependency 'prelude.Array'
    { is-object } = dependency 'prelude.Type'

    invalid-argument-value = (argument) ->

      * "Invalid argument value #{ typed-value-as-string argument }."
        "Arguments must be objects with just one property,"
        "the property name is the argument name and the property value is the argument value."
      |> (* ' ')

    argument-name-and-value = (argument) ->

      throw-error invalid-argument-value argument unless is-object argument

      member-names = object-member-names argument

      throw-error invalid-argument-value argument unless (array-size member-names) is 1

      [ argument-name ] = member-names ; argument-value = argument[ argument-name ]

      { argument-name, argument-value }

    argument-with-value = (argument) ->

      { argument-name, argument-value } = argument-name-and-value argument

      "Argument '#argument-name' with value #{ typed-value-as-string argument-value }"

    {
      argument-name-and-value,
      argument-with-value
    }