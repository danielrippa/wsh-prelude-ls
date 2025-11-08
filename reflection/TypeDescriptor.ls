
  do ->

    { create-argument-type-error: argtype, create-argument-error: argerror } = dependency 'prelude.error.Argument'
    { is-string } = dependency 'prelude.reflection.ValueType'
    { trim } = dependency 'prelude.String'

    descriptor-kinds = '<>': 'type', '{}': 'object', '[]': 'array', '()': 'function' ; descriptor-wrappers = [ (key) for key of descriptor-kinds ]

    invalid-type-descriptor-syntax-error-message = (descriptor) -> "must be sorrounded by any of #{ descriptor-wrappers * ', ' }"

    ellipsis = '...' ; is-ellipsis = (== ellipsis) ; contains-colon = (.index-of ':' isnt -1)

    token-as-types = (/ '|')
    string-as-tokens = (/ ' ')

    types-map = (descriptors) -> { [ type, yes ] for type in descriptors }

    types-from-token = (token) -> types-map token-as-types token

    name-and-types-map = (name, token) -> { name, types-map: types-map token-as-types token }

    name-and-type = (token) ->

      switch token.index-of ':'

        | -1 => name: token, types-map: null

        else [ name, type-token ] = token / ':' ; name-and-types-map name, type-token

    #

    any-descriptor = kind: 'any'

    list-descriptor = (types, descriptor) ->

      [ star, token ] = types / ':' ; throw argerror {descriptor} "is invalid. List type descriptor syntax is '*:UnionType'" if star isnt '*'

      kind: 'list', types-map: types-from-token token

    tuple-descriptor = (types) -> kind: 'tuple', types: types

    object-descriptor = (tokens) ->

      members = for token in tokens => name-and-type token
      member-names = [ m.name for m in members ]

      kind: 'object', members: members, strict: ellipsis not in member-names

    function-descriptor = (tokens) ->

      params = for token in tokens => name-and-type token
      param-names = [ p.name for p in params ]

      kind: 'function', params: params, strict: ellipsis not in param-names

    #

    parse-type-token = ([ token ]) -> if token is '?' then any-descriptor else kind: 'type', types-map: types-map token-as-types token

    parse-array-tokens = (type-tokens, descriptor) ->

      switch type-tokens.length

        | 1 =>

          [ token ] = type-tokens ; token = trim token

          match token

            | is-ellipsis => tuple-descriptor type-tokens
            | contains-colon => list-descriptor token, descriptor

        else tuple-descriptor type-tokens

    parse-object-tokens = (type-tokens) -> object-descriptor type-tokens

    parse-function-tokens = (type-tokens) -> function-descriptor type-tokens

    #

    type-descriptor = (descriptor) ->

      throw argtype 'String' {descriptor}  unless is-string descriptor ;

      [ first, ...chars, last ] = (trim descriptor) / ''

      descriptor-kind = descriptor-kinds[ "#first#last" ] ; throw argerror {descriptor} (invalid-type-descriptor-syntax-error-message descriptor) unless descriptor-kind isnt void

      type-tokens = chars |> (* '') |> trim |> (/ ' ')

      parse-tokens = switch descriptor-kind

        | 'type' => parse-type-token
        | 'array' => parse-array-tokens
        | 'object' => parse-object-tokens
        | 'function' => parse-function-tokens

      parse-tokens type-tokens, descriptor

    {
      type-descriptor
    }

