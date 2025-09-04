
  do ->

    { create-argument-type-error: argtype, create-argument-error: arg-error } = dependency 'prelude.error.Argument'
    { is-string } = dependency 'prelude.reflection.ValueType'
    { trim } = dependency 'prelude.String'

    descriptor-kinds = '<>': 'type', '{}': 'object', '[]': 'array', '()': 'function'

    descriptor-wrappers = [ (key) for key of descriptor-kinds ]

    invalid-type-descriptor-syntax-error-message = (descriptor) ->

      "must be sorrounded by any of #{ descriptor-wrappers * ', ' }"

    type-descriptor = (descriptor) ->

      throw argtype {descriptor}, 'String' unless is-string descriptor

      [ first, ...chars, last ] = (trim descriptor) / ''

      descriptor-kind = descriptor-kinds[ "#first#last" ]

      throw arg-error {descriptor}, (invalid-type-descriptor-syntax-error-message descriptor) unless descriptor-kind isnt void

      type-tokens = chars |> (* '') |> trim

      type-tokens = if (type-tokens.index-of ' ') isnt -1

        type-tokens / ' '

      else

        [ type-tokens ]



      { descriptor-kind, type-tokens }

    {
      type-descriptor, invalid-type-descriptor-syntax-error-message
    }