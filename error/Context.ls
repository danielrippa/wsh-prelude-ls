
  do ->

    { create-argument-error } = dependency 'prelude.error.Argument'
    { argument-is-a: arg-is-a } = dependency 'prelude.reflection.IsA'
    { punctuation-chars: { colon } } = dependency 'prelude.Char'
    { angle-brackets } = dependency 'prelude.Circumfix'

    spaced = (* ' ')

    namespaced = (message, qualified-namespace) ->

      namespace = [ '(Namespace', colon, " #qualified-namespace)" ] |> (* '')
      [ namespace, message ] |> spaced

    contextualized = (error, qualified-namespace) ->

      { message } = error ; message = description = namespaced message, qualified-namespace

      error <<< { message, description }

    typetags = <[ String Number Boolean Object Array Function ]>

    create-error-context = (qualified-namespace) ->

      {qualified-namespace} `arg-is-a` '<String>'

      context =

        arg-is-a: (argument, type-descriptor) ->

          try argument-value = argument `arg-is-a` type-descriptor
          catch error => throw contextualized error, qualified-namespace

          argument-value

        arg-error: (argument, message) ->

          try argument-error = create-argument-error argument, message
          catch error => throw contextualized error, qualified-namespace

          contextualized argument-error, qualified-namespace

      typetag-validator = (descriptor) -> (argument) -> context.arg-is-a argument, angle-brackets descriptor

      context <<< { [ "#{typetag}Arg", typetag-validator typetag ] for typetag in typetags }
      context <<< { [ "Maybe#{typetag}Arg", typetag-validator "#typetag|Void" ] for typetag in typetags }

    {
      create-error-context
    }
