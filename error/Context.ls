
  do ->

    { argument-type: argtype } = dependency 'prelude.reflection.Type'
    { create-argument-error: argerror, argument-with-value } = dependency 'prelude.error.Argument'
    { create-error } = dependency 'prelude.error.Error'

    { value-as-string } = dependency 'prelude.reflection.Value'

    to-string = ->

      context-string = if @contexts.length > 0 then " #{ @contexts * ' > ' }" else ''

      cause-string = if @cause isnt void
        string = if (@cause.to-string!.index-of '[native code]') isnt -1 then " #{ @cause.to-string! }" else @cause.message
        "(Cause: #string)"
      else ''

      "(Namespace #{ @qualified-namespace }#context-string) #{ @message }#cause-string"

    create-context-object = (qualified-namespace, parent-contexts = []) ->

      context-chain = parent-contexts ; contexts = context-chain.slice!

      attach-context-chain-to-error = (error) -> error <<< { qualified-namespace, contexts, to-string }

      context-function = (context-name) -> create-context-object qualified-namespace, context-chain ++ [ context-name ]

      contextualized-argtype = (descriptor, argument) ->

        try result = argtype descriptor, argument catch error => attach-context-chain-to-error error ; throw error
        result

      contextualized-argerror = (argument, message, cause) ->

        error = argerror argument, message, cause ; attach-context-chain-to-error error
        error

      create-contextualized-error = (message, cause) ->

        error = create-error message, cause ; attach-context-chain-to-error error
        error

      contextualize-error = (error) -> attach-context-chain-to-error error ; error

      context: context-function
      argtype: contextualized-argtype
      argerror: contextualized-argerror

      create-error: create-contextualized-error
      contextualized: contextualize-error

      argument: argument-with-value

    create-error-context = (qualified-namespace) -> create-context-object qualified-namespace

    {
      create-error-context
    }