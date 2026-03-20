

  do ->

    { create-argument-error: arg, create-argument-requirement-error: arg-must } = dependency 'prelude.error.Argument'
    { trim-whitespace } = dependency 'prelude.Whitespace'
    { is-string } = dependency 'prelude.Type'
    { string-split-with } = dependency 'prelude.RegExp'
    { drop-array-items, array-size, map-array-items: map } = dependency 'prelude.Array'
    { punctuation-chars } = dependency 'prelude.Char'
    { string-starts-with: starts-with, string-contains } = dependency 'prelude.String'
    { camel-case } = dependency 'prelude.Case'

    { period, question: wildcard, asterisk: star, space, colon, pipe } = punctuation-chars

    drop-empty-strings = _ `drop-array-items` (== '')

    ellipsis = "#period" * 3

    string-as-tokens = string-split-with space
    split-by-pipe = string-split-with pipe
    split-by-colon = string-split-with colon

    contains-colon = -> it `string-contains` colon

    is-special-token = (token) -> token is ellipsis or token is wildcard

    #

    types-map = (types) -> { [ type, yes ] for type in types }

    token-as-union-types = -> it |> split-by-pipe |> drop-empty-strings

    token-as-types-map = -> it |> token-as-union-types |> types-map

    get-named-types-descriptor = (kind, tokens, parse-item) ->

      items = map tokens, parse-item

      { kind, descriptor-tokens: items }

    chars-as-tokens = (chars) -> chars * '' |> trim-whitespace |> string-as-tokens |> drop-empty-strings

    build-names-map = (name) -> { [ (camel-case name-variant), yes ] for name-variant in (split-by-pipe name) when name-variant isnt '' }

    #

    parse-type-tokens = (tokens, descriptor) ->

      throw {descriptor} `arg-must` "specify a UnionType e.g. <Number|Void> or <?> for any type" unless (array-size tokens) is 1

      [ token ] = tokens

      if token is wildcard
        then kind: 'any'
        else kind: 'type', types-map: token-as-types-map token

    #

    tuple-element = (token) ->
      { token, types-map: if is-special-token token then void else token-as-types-map token }

    tuple-descriptor = (tokens) -> kind: 'tuple', element-types-map: map tokens, tuple-element

    list-descriptor = (type, descriptor) ->

      return kind: 'list' if type is star

      [ initial, union-type ] = type |> split-by-colon

      throw {descriptor} `arg` "is invalid. Array descriptor syntax is '[*]' for items of any type or '[*:UnionType]' for specific types" \
        unless initial is star and union-type isnt ''

      kind: 'list', types-map: token-as-types-map union-type

    parse-array-tokens = (tokens, descriptor) ->

      switch array-size tokens

        | 0 => tuple-descriptor tokens
        | 1 =>

          [ token ] = tokens

          if token `starts-with` star
            then list-descriptor token, descriptor
            else tuple-descriptor tokens

        else tuple-descriptor tokens

    #

    parse-object-member = (name) ->

      type-token = void

      if name |> contains-colon

        then

          [ name, type-token ] = split-by-colon name

          throw {name} `arg` "is invalid. Object member cannot have empty type after colon" if type-token is ''

      { name, type-token }

    parse-object-tokens = (tokens, descriptor) ->

      get-named-types-descriptor 'object', tokens, (token) ->

        { name, type-token } = parse-object-member token
        types-map = if type-token isnt void then token-as-types-map type-token else void

        { token: name, types-map, names-map: build-names-map name }

    #

    parse-function-tokens = (tokens, descriptor) ->

      get-named-types-descriptor 'function', tokens, (token) ->

        throw {token} `arg` "is invalid. Function parameters cannot include type annotations" if token |> contains-colon

        { token, types-map: void, names-map: build-names-map token }

    #

    descriptor-kind-keys = <[ <> [] {} () ]> ; descriptor-names = <[ type array object function ]>

    descriptor-kinds = { [ descriptor-kind-keys[index], descriptor-name ] for descriptor-name, index in descriptor-names }

    cached-type-descriptors = {} ; type-descriptor = (descriptor) ->

      throw {descriptor} `arg-must` "be String" unless is-string descriptor
      descriptor = trim-whitespace descriptor
      throw {descriptor} `arg` "cannot be empty" if descriptor is ''

      cached-type-descriptor = cached-type-descriptors[ descriptor ] => return .. unless .. is void

      [ first, ...chars, last ] = descriptor / ''

      descriptor-kind = descriptor-kinds[ "#first#last" ]

      throw {descriptor} `arg-must` "be surrounded by any of #{ descriptor-kind-keys * ', ' }" \
        if descriptor-kind is void

      parse = switch descriptor-kind

        | 'type'     => parse-type-tokens
        | 'array'    => parse-array-tokens
        | 'object'   => parse-object-tokens
        | 'function' => parse-function-tokens

      parse (chars |> chars-as-tokens), descriptor => cached-type-descriptors[ descriptor ] := ..

    {
      type-descriptor,
      ellipsis, wildcard, is-special-token
    }
