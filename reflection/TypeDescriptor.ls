
  do ->

    { create-argument-type-error: argument-type-error, create-argument-error: argument-error } = dependency 'prelude.error.Argument'
    { is-string } = dependency 'prelude.Type'
    { string-contains, string-repeat } = dependency 'prelude.String'
    { string-split-with } = dependency 'prelude.RegExp'
    { trim-whitespace } = dependency 'prelude.Whitespace'
    { punctuation-chars } = dependency 'prelude.Char'
    { object-member-names } = dependency 'prelude.Object'
    { array-size, drop-array-items } = dependency 'prelude.Array'

    descriptor-kinds =

      '<>': 'type'
      '[]': 'array'
      '{}': 'object'
      '()': 'function'

    descriptor-kind-keys = object-member-names descriptor-kinds

    #

    { period, pipe, space, colon } = punctuation-chars

    ellipsis = string-repeat period, 3 ; is-ellipsis = (== ellipsis)

    contains-colon = -> string-contains it, colon

    is-not-empty = (str) -> str isnt ''

    split-by-pipe = string-split-with pipe
    token-as-types = (token) -> token |> split-by-pipe |> drop-array-items _, (== '')
    string-as-tokens = string-split-with space
    split-by-colon = string-split-with colon

    #

    types-map = (descriptors) -> { [ type, yes ] for type in descriptors }

    types-from-token = (token) -> types-map token-as-types token

    name-and-types-map = (name, token) -> { name, types-map: types-from-token token }

    object-member = (token) ->

      if token `string-contains` colon
        then [ name, type-token ] = split-by-colon token ; throw argument-error {token}, "is invalid. Object member cannot have empty type after colon." if type-token is '' ; name-and-types-map name, type-token
        else name: token, types-map: null

    function-param = (token) ->

      throw argument-error {token}, "is invalid. Function parameters cannot include type annotations." if token `string-contains` colon

      name: token, types-map: null

    #

    any-descriptor = kind: 'any'

    invalid-list-syntax-message = "is invalid. Array descriptor syntax is '[*]' for any type or '[*:UnionType]' for specific types."

    parse-type-token = ([ token ]) ->

      throw argument-error {descriptor: '<>'}, "is invalid. Type descriptor cannot be empty." if token is void

      switch token

        | '?' => any-descriptor
        else
          types = token-as-types token
          all-types = split-by-pipe token
          throw argument-error {descriptor: "<#token>"}, "is invalid. Type descriptor contains empty type in union." if (array-size all-types) > (array-size types)
          throw argument-error {descriptor: "<#token>"}, "is invalid. Type descriptor must contain at least one type." if (array-size types) is 0
          kind: 'type', types-map: types-map types

    #

    tuple-descriptor = (types) -> kind: 'tuple', types: types

    list-descriptor = (types, descriptor) ->

      throw argument-error {descriptor}, invalid-list-syntax-message unless contains-colon types

      [ initial, token ] = split-by-colon types

      switch initial

        | '*' =>
          throw argument-error {descriptor}, invalid-list-syntax-message if token is ''
          kind: 'list', types-map: types-from-token token
        else throw argument-error {descriptor}, invalid-list-syntax-message

    parse-array-tokens = (type-tokens, descriptor) ->

      switch array-size type-tokens

        | 0 => tuple-descriptor type-tokens
        | 1 =>
          [ token ] = type-tokens

          switch

            | is-ellipsis token => tuple-descriptor type-tokens
            | contains-colon token => list-descriptor token, descriptor
            else tuple-descriptor type-tokens

        else tuple-descriptor type-tokens

    #

    named-items-descriptor = (kind, items-name, tokens, item-parser) ->

      items = [ (item-parser token) for token in tokens ]
      item-names = [ (item.name) for item in items ]

      { kind, (items-name): items, strict: ellipsis not in item-names }

    parse-object-tokens = (tokens) -> named-items-descriptor 'object', 'members', tokens, object-member

    #

    parse-function-tokens = (tokens) -> named-items-descriptor 'function', 'params', tokens, function-param

    #

    invalid-type-descriptor-message = "must be surrounded by any of #{ descriptor-kind-keys * ', ' }"

    chars-as-tokens = (chars) -> chars |> (* '') |> trim-whitespace |> string-as-tokens |> drop-array-items _ , (== '')

    type-descriptor = (descriptor) ->

      throw argument-error {descriptor}, "must be a String." unless is-string descriptor

      trimmed = trim-whitespace descriptor

      throw argument-error {descriptor}, "cannot be empty" if trimmed is ''

      [ first, ...chars, last ] = trimmed / ''

      descriptor-kind = descriptor-kinds[ "#first#last" ]

      throw argument-error {descriptor}, invalid-type-descriptor-message if descriptor-kind is void

      parse-tokens-fn = switch descriptor-kind

        | 'type' => parse-type-token
        | 'array' => parse-array-tokens
        | 'object' => parse-object-tokens
        | 'function' => parse-function-tokens

      parse-tokens-fn (chars-as-tokens chars), descriptor

    {
      type-descriptor
    }

