
  do ->

    { create-error } = dependency 'prelude.error.Error'
    { is-object } = dependency 'prelude.reflection.ValueType'
    { typed-value-as-string } = dependency 'prelude.reflection.Value'

    object-member-names = (object) -> [ (member-name) for member-name of object ]

    argument-as-string = (argument-name, argument-value) ->

      "Argument '#argument-name' with value #{ typed-value-as-string argument-value }"

    argument-must-message = (argument-name, argument-value, requirement) ->

      "#{ argument-as-string argument-name, argument-value } must #requirement"

    name-and-value-from-argument = (argument) ->

      throw create-error "#{ argument-must-message 'argument', argument, 'be Object' }" \
        unless is-object argument

      member-names = object-member-names argument

      throw create-error "#{ argument-must-message 'object argument', argument, 'have only one member.' }" \
        unless member-names.length is 1

      [ argument-name ] = member-names ; argument-value = argument[ argument-name ]

      { argument-name, argument-value }

    create-argument-error = (argument, message, cause) ->

      { argument-name, argument-value } = name-and-value-from-argument argument

      create-error "#{ argument-as-string argument-name, argument-value } #message.", cause

    create-argument-requirement-error = (argument, requirement, cause) ->

      { argument-name, argument-value } = name-and-value-from-argument argument

      create-error "#{ argument-must-message argument-name, argument-value, requirement }.", cause

    create-argument-type-error = (argument, type, cause) -> create-argument-requirement-error argument, "be #type", cause

    argument-with-value = (argument) -> argument |> name-and-value-from-argument |> argument-as-string

    {
      create-argument-error,
      create-argument-requirement-error,
      create-argument-type-error,
      name-and-value-from-argument,
      argument-with-value
    }
