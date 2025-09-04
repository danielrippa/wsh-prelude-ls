
  do ->

    { type-descriptor } = dependency 'prelude.reflection.TypeDescriptor'
    { create-argument-error: arg-error, create-argument-type-error: argtype, create-argument-requirement-error: arg-req, name-and-value-from-argument, argument-with-value } = dependency 'prelude.error.Argument'
    { is-a, is-any-of, is-array, is-object, is-function } = dependency 'prelude.reflection.IsA'
    { trim } = dependency 'prelude.String'
    { map, filter } = dependency 'prelude.Array'
    { value-as-string, typed-value-as-string } = dependency 'prelude.reflection.Value'
    { kebab-case, camel-case } = dependency 'prelude.String'
    { function-parameter-names } = dependency 'prelude.Function'
    { create-error } = dependency 'prelude.error.Error'

    ellipsis = '...'

    token-as-types = (/ '|')

    csv = (* ', ')

    any-of = (tokens) ->

      prefix = if tokens.length is 1 then '' else 'any of '
      "#{prefix}#{ csv tokens }"

    #

    consume-for-ellipsis = (items-count, tokens-count, item-index, token-index) ->

      remaining-tokens-count = tokens-count - token-index
      items-to-leave = remaining-tokens-count
      stop-item-index = items-count - items-to-leave

      if item-index > stop-item-index
        return item-index

      stop-item-index

    with-descriptor = (message, descriptor, kind = 'type') -> "#{message} as per #{kind} type descriptor '#{descriptor}'"

    count-error = (subject, subject-type, expected, actual, strict, descriptor) ->

      qualifier = if strict then '' else 'at least '
      arg-error {subject}, with-descriptor "#subject-type has #actual items. It must have #qualifier#expected", descriptor

    tuple-size-error = (tuple, expected, elements-count, strict, descriptor) -> count-error tuple, 'Tuple', expected, elements-count, strict, descriptor

    object-member-count-error = (object, expected, members-count, strict, descriptor) -> count-error object, 'Object', expected, members-count, strict, descriptor

    function-parameter-count-error = (fn, expected, actual, strict, descriptor) -> count-error fn, 'Function', expected, actual, strict, descriptor

    array-item-type-mismatch-error = (array, types, descriptor, index) ->

      item = array[ index ] ; arg-error {item}, with-descriptor "at index #index must be #{ any-of types }", descriptor, 'list'

    tuple-element-type-mismatch-error = (tuple, types, descriptor, element-index, type-index) ->

      token = types[ type-index ] ; types = token-as-types token ; element = tuple[ element-index ]

      arg-error {element}, with-descriptor "at index #element-index must be #{ any-of types }", descriptor, 'tuple'

    unexpected-trailing-elements-error = (tuple, descriptor, element-index, was-prev-ellipsis) ->

      unexpected-elements = tuple |> (.slice element-index) |> map _ , typed-value-as-string |> csv

      suffix = if was-prev-ellipsis then " after its variadic '#ellipsis' part" else ''

      arg-error {tuple}, with-descriptor "has trailing elements #unexpected-elements not defined#{suffix}", descriptor, 'tuple'

    missing-mandatory-types-error = (tuple, descriptor, missing-mandatory-types) ->

      message = if missing-mandatory-types.length is 0
        ''
      else
        " #{ csv missing-mandatory-types }"

      arg-error {tuple}, with-descriptor "is missing mandatory elements#message", descriptor, 'tuple'

    missing-member-error = (object, member-name, descriptor) -> arg-error {object}, with-descriptor "is missing member '#{ kebab-case member-name }'", descriptor, 'object'

    tuple-too-short-error = (tuple, types, descriptor, type-index) ->

      types-count = types.length ; missing-mandatory-types = []

      loop

        break unless type-index < types-count

        token = types[ type-index ]

        break if (token is '?') or (token is ellipsis)

        missing-mandatory-types.push token

        type-index++

      missing-mandatory-types-error tuple, descriptor, missing-mandatory-types

    valid-tuple-size = (tuple, strict, elements-count, types, descriptor) ->

      if strict

        throw tuple-size-error tuple, types.length, elements-count, strict, descriptor \
          if elements-count isnt types.length

      else

        non-ellipsis-count = filter types, (!= ellipsis) .length
        throw tuple-size-error tuple, non-ellipsis-count, elements-count, strict, descriptor \
          if elements-count < non-ellipsis-count

    handle-tuple-is-done = (tuple, types, descriptor, type-index) ->

      token = types[ type-index ] ; prev-ellipsis = token is ellipsis

      throw tuple-too-short-error tuple, types, descriptor, type-index \
        unless (token is '?') or prev-ellipsis

      { type-index: (type-index + 1), prev-ellipsis }

    #

    tuple-with-types = (tuple, [ descriptor, types ]) ->

      strict = ellipsis not in types ; elements-count = tuple.length ; types-count = types.length

      valid-tuple-size tuple, strict, elements-count, types, descriptor

      element-index = type-index = 0 ; increment-indexes = -> element-index++ ; type-index++
      current-element = (-> tuple[ element-index ]) ; current-type = (-> types[ type-index ])

      prev-ellipsis = no

      loop

        tuple-is-done = element-index is elements-count ; types-is-done = type-index is types-count
        break if tuple-is-done and types-is-done

        if tuple-is-done

          { type-index, prev-ellipsis } = handle-tuple-is-done tuple, types, descriptor, type-index ; continue

        ellipsis-context = prev-ellipsis
        prev-ellipsis = no

        throw unexpected-trailing-elements-error tuple, descriptor, element-index, ellipsis-context \
          if types-is-done

        token = current-type! 

        if token is '?' => increment-indexes! ; continue

        unless strict

          if token is ellipsis

            type-index++ ; element-index = consume-for-ellipsis elements-count, types-count, element-index, type-index
            prev-ellipsis = yes ; continue

        throw tuple-element-type-mismatch-error tuple, types, descriptor, element-index, type-index \
          unless current-element! `is-any-of` token-as-types token

        increment-indexes!

      tuple

    #

    array-with-type = (array, [ descriptor, token ]) ->

      types = token-as-types token

      for item, index in array => unless item `is-any-of` types

        throw array-item-type-mismatch-error array, types, descriptor, index

      array

    #

    value-with-type = (value, [ descriptor, tokens ]) ->

      throw argtype {descriptor}, "be exactly one token" \
        unless tokens.length is 1

      [ token ] = tokens ; return value if token is '?'

      union-types = token-as-types token ; return value if value `is-any-of` union-types

      throw argtype {value}, with-descriptor "#{ any-of union-types }", descriptor

    #

    array-with-types = (array, [ descriptor, tokens ]) ->

      throw argtype {value}, with-descriptor "Array", descriptor \
        unless is-array array

      if tokens.length is 1

        [ token ] = tokens ; token = trim token

        if token is ellipsis => return tuple-with-types array, [ descriptor, tokens ]

        if (token.index-of ':') isnt -1

          [ star, types ] = token / ':'

          if star is '*'
            return array-with-type array, [ descriptor, types ]
          else
            throw arg-error {descriptor} "is invalid. List type descriptor syntax is '*:UnionType'"

      else

        return tuple-with-types array, [ descriptor, tokens ]

    #

    object-with-members = (object, [ descriptor, tokens ]) ->

      throw argtype {object}, with-descriptor "Object", descriptor, 'object' \
        unless is-object object

      member-names = [ (kebab-case member-name) for member-name of object ] ; members-count = member-names.length
      strict = ellipsis not in tokens

      all-object-tokens = filter tokens, (!= ellipsis) ; tokens-count = all-object-tokens.length
      anonymous-token-count = filter all-object-tokens, (== '?') .length

      throw object-member-count-error object, tokens-count, members-count, strict, descriptor \
        if (strict and members-count isnt tokens-count) or (not strict and members-count < tokens-count)

      unmatched-members = [ ...member-names ]

      processable-object-tokens = filter all-object-tokens, (!= '?')

      for token in processable-object-tokens

        if (token.index-of ':') is -1

          throw missing-member-error object, member-name-token, descriptor \
            unless token in unmatched-members

          unmatched-members = filter unmatched-members, (!= token)

        else

          [ member-name-token, type-token ] = token / ':'

          throw missing-member-error object, member-name-token, descriptor \
            unless member-name-token in unmatched-members

          member-value = object[ camel-case member-name-token ]

          types = token-as-types type-token

          throw arg-error {object}, with-descriptor "must have member '#{ kebab-case member-name-token }' with type #{ any-of types }", descriptor, 'object' \
            unless member-value `is-any-of` types

          unmatched-members = filter unmatched-members, (!= member-name-token)

      if strict

        throw arg-error {object}, with-descriptor "has unmatched member(s) #{ csv unmatched-members } but expected #{ anonymous-token-count }", descriptor, 'object' \
          if unmatched-members.length isnt anonymous-token-count

      object

    #

    function-with-parameters = (fn, [ descriptor, tokens ]) ->

      throw argtype {fn}, with-descriptor "Function", descriptor, 'function' \
        unless is-function fn

      parameter-names = function-parameter-names fn ; parameters-count = parameter-names.length
      strict = ellipsis not in tokens

      token-index = 0
      param-index = 0

      while token-index < tokens.length
        token = tokens[token-index]

        if token is ellipsis
          token-index++
          param-index = consume-for-ellipsis parameters-count, tokens.length, param-index, token-index
          continue

        if token is '?'
          if param-index < parameters-count => param-index++
          token-index++
          continue

        throw arg-error {fn}, with-descriptor "is missing parameter for token: #{token}", descriptor \
          if param-index >= parameters-count

        parameter-name = parameter-names[ param-index ]

        name-token = token
        if (token.index-of ':') isnt -1
          [ name-token, type-token ] = token / ':'

        throw arg-error {fn}, "Parameter name mismatch at index #{param-index}. Expected '#{name-token}' but got '#{parameter-name}'" \
          if (camel-case name-token) isnt parameter-name

        param-index++
        token-index++

      throw arg-error {fn}, with-descriptor "has more parameters than expected", descriptor \
        if strict and param-index < parameters-count

      fn

    type = (descriptor, value) ->

      { descriptor-kind, type-tokens } = type-descriptor descriptor

      value-with-type-tokens = switch descriptor-kind

        | 'type' => value-with-type
        | 'array' => array-with-types
        | 'object' => object-with-members
        | 'function' => function-with-parameters

      value `value-with-type-tokens` [ descriptor, type-tokens ]

    argument-type = (descriptor, argument) ->

      { argument-name, argument-value } = name-and-value-from-argument argument

      try type descriptor, argument-value
      catch error => throw create-error "#{ argument-with-value argument-name, argument-value } is not valid as per type descriptor '#descriptor'.", error

    {
      type, argument-type
    }