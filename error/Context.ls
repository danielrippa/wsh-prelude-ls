
  do ->

    { argument-type: argtype } = dependency 'prelude.reflection.Type'
    { create-argument-error: argerror } = dependency 'prelude.error.Argument'

    create-context-object = (qualified-namespace, parent-contexts = []) ->

      context-chain = parent-contexts ; contexts = context-chain.slice!

      attach-context-chain-to-error = (error) -> error <<< { qualified-namespace, contexts }

      context-function = (context-name) -> create-context-object qualified-namespace, context-chain ++ [ context-name ]

      contextualized-argtype = (value, descriptor) ->

        try result = argtype value, descriptor catch error => attach-context-chain-to-error error ; throw error
        result

      contextualized-argerror = (argument, message, cause) ->

        error = arg-error argument, message, cause ; attach-context-chain-to-error error
        error

      context: context-function
      argtype: contextualized-argtype
      argerror: contextualized-argerror

    create-error-context = (qualified-namespace) -> create-context-object qualified-namespace

    {
      create-error-context
    }