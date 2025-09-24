
  do ->

    { create-error-context } = dependency 'prelude.error.Context'

    { argtype } = create-error-context 'prelude.error.Value'

    value-or-error = (fn) -> error = void ; (try value = (argtype '<Function>' {fn})! catch error) ; { error, value }

    {
      value-or-error
    }