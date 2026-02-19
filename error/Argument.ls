
  do ->

    { argument-name-and-value, argument-with-value } = dependency 'prelude.reflection.Argument'
    { create-error } = dependency 'prelude.Error'

    { typed-value-as-string } = dependency 'prelude.Value'

    create-argument-error = (argument, message, cause) ->

      { argument-name, argument-value } = argument-name-and-value argument

      create-error "#{ argument-with-value argument } #message.", cause

    create-argument-requirement-error = (argument, requirement, cause) ->

      create-argument-error argument, "must #requirement", cause

    create-argument-type-error = (argument, type, cause) ->

      create-argument-requirement-error argument, "be #type", cause

    {
      create-argument-error,
      create-argument-requirement-error,
      create-argument-type-error
    }