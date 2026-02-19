
  do ->

    { argument-type: argtype } = dependency 'prelude.reflection.Argument'
    { create-argument-error } = dependency 'prelude.error.Argument'
    { create-error } = dependency 'prelude.Error'
    { punctuation-chars: { colon } } = dependency 'prelude.Char'

    namespaced = (message, qualified-namespace) ->

      prefix = [ 'Namespace', colon, qualified-namespace ] * ' '
      [ prefix, message ] * ' '

    contextualized = (error, qualified-namespace) ->

      { message } = error ; message = description = namespaced message, qualified-namespace

      error <<< { message, description }

    create-error-context = (qualified-namespace) ->

      argtype '<String>' {qualified-namespace}

      argtype: (type-descriptor, argument) ->

        try argument-value = argtype type-descriptor, argument
        catch error => throw contextualized error, qualified-namespace

        argument-value

    {
      create-error-context
    }

