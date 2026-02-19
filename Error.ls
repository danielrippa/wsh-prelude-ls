
  do ->

    { is-string } = dependency 'prelude.Type'
    { string-repeat } = dependency 'prelude.String'
    { control-chars: { lf } } = dependency 'prelude.Char'

    indentation = string-repeat ' ', 2

    create-error = (message, cause) ->

      return null unless is-string message

      if cause isnt void => message = [ message, lf, indentation, 'Caused by: ', cause.message ] * ''

      new Error message => .. <<< { cause } if cause isnt void

    throw-error = (message, cause) -> throw create-error message, cause

    {
      create-error, throw-error
    }

