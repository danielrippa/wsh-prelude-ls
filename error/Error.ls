
  do ->

    { is-string } = dependency 'prelude.reflection.ValueType'

    create-error = (message, cause) -> return null unless is-string message ; new Error message => .. <<< { cause } if cause isnt void

    {
      create-error
    }