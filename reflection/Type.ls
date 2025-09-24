
  do ->

    { type-descriptor } = dependency 'prelude.reflection.TypeDescriptor'
    { create-argument-error: arg-error, create-argument-type-error: argtype, create-argument-requirement-error: arg-req, name-and-value-from-argument, argument-with-value } = dependency 'prelude.error.Argument'
    { is-a, is-array, is-object, is-function, is-any-of, matches-any } = dependency 'prelude.reflection.IsA'
    { trim } = dependency 'prelude.String'
    { map, filter } = dependency 'prelude.Array'
    { value-as-string, typed-value-as-string } = dependency 'prelude.reflection.Value'
    { kebab-case, camel-case } = dependency 'prelude.String'
    { function-parameter-names } = dependency 'prelude.Function'
    { create-error } = dependency 'prelude.error.Error'
    { object-member-names } = dependency 'prelude.Object'

    parsed-type-descriptors = {}

    ellipsis = '...'
    token-as-types = (/ '|')
    csv = (* ', ')

    any-of = (tokens) -> prefix = (if tokens.length is 1 then '' else 'any of ') ; "#{prefix}#{ csv tokens }"

    with-descriptor = (message, descriptor, kind = 'type') -> "#{message} as per #{kind} type-descriptor '#{descriptor}'"

    #

    count-error = (subject, subject-type, expected, actual, strict, descriptor) -> qualifier = if strict then '' else 'at least ' ; arg-error {subject}, with-descriptor "#subject-type has #actual items. It must have #qualifier#expected", descriptor

    tuple-size-error = (tuple, expected, elements-count, strict, descriptor) -> count-error tuple, 'Tuple', expected, elements-count, strict, descriptor

    object-member-count-error = (object, expected, members-count, strict, descriptor) -> count-error object, 'Object', expected, members-count, strict, descriptor

    function-parameter-count-error = (fn, expected, actual, strict, descriptor) -> count-error fn, 'Function', expected, actual, strict, descriptor

    list-item-type-mismatch-error = (array, types, descriptor, index) ->

      item = array[ index ] ; arg-error {item} "at index #index must be #{ any-of types } as per list type descriptor '#descriptor'"

    tuple-element-type-mismatch-error = (tuple, types, descriptor, element-index, type-index) ->

      token = types[ type-index ] ; types = token-as-types token ; element = tuple[ element-index ]
      arg-error {element}, "at index #element-index must be #{ any-of types } as per tuple type descriptor '#descriptor'"

    unexpected-trailing-elements-error = (tuple, descriptor, element-index, was-prev-ellipsis) ->

      unexpected-elements = tuple |> (.slice element-index) |> map _ , typed-value-as-string |> csv
      suffix = if was-prev-ellipsis then " after its variadic '#ellipsis' part" else ''

      arg-error {tuple}, with-descriptor "has trailing elements #unexpected-elements not defined#{suffix}", descriptor, 'tuple'

    missing-mandatory-types-error = (tuple, descriptor, missing-mandatory-types) ->

      message = if missing-mandatory-types.length is 0 then '' else " #{ csv missing-mandatory-types }"
      arg-error {tuple}, with-descriptor "is missing mandatory elements#message", descriptor, 'tuple'

    missing-member-error = (object, member-name, descriptor) -> arg-error {object}, with-descriptor "is missing member '#{ kebab-case member-name }'", descriptor, 'object'

    tuple-too-short-error = (tuple, types, descriptor, type-index) ->

      types-count = types.length ; missing-mandatory-types = []

      loop

        break unless type-index < types-count
        token = types[ type-index ] ; break if (token is '?') or (token is ellipsis)

        missing-mandatory-types.push token
        type-index++

      missing-mandatory-types-error tuple, descriptor, missing-mandatory-types

    #

    handle-tuple-is-done = (tuple, types, descriptor, type-index) ->

      token = types[ type-index ] ; prev-ellipsis = token is ellipsis ; throw tuple-too-short-error tuple, types, descriptor, type-index unless (token is '?') or prev-ellipsis
      { type-index: (type-index + 1), prev-ellipsis }

    valid-tuple-size = (tuple, strict, elements-count, types, descriptor) ->

      if strict
        throw tuple-size-error tuple, types.length, elements-count, strict, descriptor if elements-count isnt types.length
      else
        non-ellipsis-count = filter types, (!= ellipsis) .length
        throw tuple-size-error tuple, non-ellipsis-count, elements-count, strict, descriptor if elements-count < non-ellipsis-count

    consume-for-ellipsis = (items-count, tokens-count, item-index, token-index) ->

      remaining-tokens-count = tokens-count - token-index ; items-to-leave = remaining-tokens-count
      stop-item-index = items-count - items-to-leave ; if item-index > stop-item-index then item-index else stop-item-index

    #

    union-type = (value, { types-map }, descriptor) ->

      throw argtype {value}, with-descriptor "#{ any-of object-member-names types-map }", descriptor unless value `matches-any` types-map ; value

    list-type = (list, { types-map }, descriptor) ->

      throw argtype {list}, with-descriptor "Array", descriptor unless is-array list

      for item, index in list => throw list-item-type-mismatch-error list, (object-member-names types-map), descriptor, index unless item `matches-any` types-map

      list

    tuple-type = (tuple, { types }, descriptor) ->

      throw argtype {tuple}, with-descriptor "Array", descriptor unless is-array tuple

      strict = ellipsis not in types ; elements-count = tuple.length ; types-count = types.length ; valid-tuple-size tuple, strict, elements-count, types, descriptor

      element-index = type-index = 0 ; increment-indexes = (-> element-index++ ; type-index++)

      current-element = (-> tuple[ element-index ]) ; current-type = (-> types[ type-index ])

      prev-ellipsis = no

      loop

        tuple-is-done = element-index is elements-count ; types-is-done = type-index is types-count ; break if tuple-is-done and types-is-done

        if tuple-is-done
          { type-index, prev-ellipsis } = handle-tuple-is-done tuple, types, descriptor, type-index ; continue

        ellipsis-context = prev-ellipsis ; prev-ellipsis = no ; throw unexpected-trailing-elements-error tuple, descriptor, element-index, ellipsis-context \
          if types-is-done

        token = current-type! ; if token is '?' => increment-indexes! ; continue

        unless strict
          if token is ellipsis
            type-index++ ; element-index = consume-for-ellipsis elements-count, types-count, element-index, type-index
            prev-ellipsis = yes ; continue

        throw tuple-element-type-mismatch-error tuple, types, descriptor, element-index, type-index \
          unless (current-element!) `is-any-of` (token-as-types token)

        increment-indexes!

      tuple

    object-type = (object, { members, strict }, descriptor) ->

      throw argtype {value}, with-descriptor "Object", descriptor, 'object' unless is-object object

      member-names = [ (kebab-case member-name) for member-name of object ] ; members-count = member-names.length
      tokens-count = members.length

      if strict
        throw object-member-count-error object, tokens-count, members-count, strict, descriptor if members-count isnt tokens-count
      else
        non-ellipsis-tokens = filter members, (.name isnt ellipsis) ; non-ellipsis-count = non-ellipsis-tokens.length
        if members-count < non-ellipsis-count
          throw object-member-count-error object, non-ellipsis-count, members-count, strict, descriptor

      unmatched-members = [ ...member-names ]
      processable-object-tokens = members |> filter _ , (.name isnt '?') |> filter _ , (.name isnt ellipsis)
      anonymous-token-count = filter members, (.name is '?') .length

      for token in processable-object-tokens

        { name, types-map } = token ; throw missing-member-error object, name, descriptor unless name in unmatched-members

        if types-map isnt null

          member-value = object[ camel-case name ] ; throw arg-error {object}, with-descriptor "must have member '#{ kebab-case name }' with type #{ any-of object-member-names types-map }", descriptor, 'object' unless member-value `matches-any` types-map

        unmatched-members = filter unmatched-members, (!= name)

      if strict => throw arg-error {object}, with-descriptor "has unmatched member(s) #{ csv unmatched-members } but expected #{ anonymous-token-count }", descriptor, 'object' if unmatched-members.length isnt anonymous-token-count

      object

    function-type = (fn, { params, strict }, descriptor) ->

      parameter-names = function-parameter-names fn ; parameters-count = parameter-names.length
      token-index = 0 ; param-index = 0

      while token-index < params.length

        token = params[token-index]

        if token.name is ellipsis
          token-index++ ; param-index = consume-for-ellipsis parameters-count, params.length, param-index, token-index
          continue

        if token.name is '?'
          token-index++ ; if param-index < parameters-count => param-index++
          continue

        throw arg-error {fn}, with-descriptor "is missing parameter for token: #{token.name}", descriptor if param-index >= parameters-count

        parameter-name = parameter-names[ param-index ]
        throw arg-error {fn}, "Parameter name mismatch at index #{param-index}. Expected '#{token.name}' but got '#{parameter-name}'" if (camel-case token.name) isnt parameter-name

        param-index++ ; token-index++

      throw arg-error {fn}, with-descriptor "has more parameters than expected", descriptor if strict and param-index < parameters-count

      fn

    #

    type = (descriptor, value) ->

      parsed-descriptor = parsed-type-descriptors[ descriptor ] ; if parsed-descriptor is void => parsed-descriptor = type-descriptor descriptor ; parsed-type-descriptors[ descriptor ] := parsed-descriptor

      { kind } = parsed-descriptor ; return value if kind is 'any'

      value-type = switch parsed-descriptor.kind

        | 'type'     => union-type
        | 'list'     => list-type
        | 'tuple'    => tuple-type
        | 'object'   => object-type
        | 'function' => function-type

      value-type value, parsed-descriptor, descriptor

    #

    argument-type = (descriptor, argument) ->

      { argument-name, argument-value } = name-and-value-from-argument argument

      type descriptor, argument-value

      argument-value

    {
      type, argument-type
    }