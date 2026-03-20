

  do ->

    { type-descriptor, ellipsis, wildcard, is-special-token } = dependency 'prelude.reflection.TypeDescriptor'
    { create-argument-requirement-error: arg-must } = dependency 'prelude.error.Argument'
    { object-member-names: get-member-names } = dependency 'prelude.Object'
    { value-typename } = dependency 'prelude.TypeName'
    { value-typetag, is-array } = dependency 'prelude.TypeTag'
    { value-type, is-object, is-function } = dependency 'prelude.Type'
    { array-size, array-sort } = dependency 'prelude.Array'
    { function-parameter-names } = dependency 'prelude.Function'
    { camel-case } = dependency 'prelude.Case'
    { argument-name-and-value } = dependency 'prelude.reflection.Argument'

    analyze-descriptor-tokens = (descriptor-tokens) ->

      tokens-count = array-size descriptor-tokens
      has-ellipsis = no
      for entry in descriptor-tokens => has-ellipsis = yes if entry.token is ellipsis

      [ tokens-count, has-ellipsis ]

    any-of = (types-map) ->

      type-tokens = get-member-names types-map
      quantifier = if (array-size type-tokens) is 1 then '' else 'any of '

      [ quantifier, type-tokens * ', ' ] * ''

    as-per = (kind, descriptor) -> "as per #kind descriptor '#descriptor'"

    #

    skip-special-entries = (entries, entries-count, index) ->

      loop

        return index if index >= entries-count or not is-special-token entries[index].token
        index++

    skip-ellipsis-entries = (entries, entries-count, index) ->

      loop

        return index if index >= entries-count or entries[index].token isnt ellipsis
        index++

    handle-special-entry = (items-count, entries-count, idx1, idx2, token) ->

      switch token

        | wildcard => idx1++ ; idx2++
        | ellipsis =>

          tokens-after = entries-count - idx2 - 1
          last-index = items-count - tokens-after
          idx1 = if idx1 > last-index then idx1 else last-index
          idx2++

      [ idx1, idx2 ]

    skip-special-tokens = (tokens, tokens-count, index) ->

      loop

        return index if index >= tokens-count or not is-special-token tokens[index]
        index++

    skip-ellipsis-tokens = (tokens, tokens-count, index) ->

      loop

        return index if index >= tokens-count or tokens[index].token isnt ellipsis
        index++

    handle-special-token = (items-count, tokens-count, idx1, idx2, token) ->

      switch token

        | wildcard => idx1++ ; idx2++
        | ellipsis =>

          tokens-after = tokens-count - idx2 - 1
          last-index = items-count - tokens-after
          idx1 = if idx1 > last-index then idx1 else last-index
          idx2++

      [ idx1, idx2 ]

    #

    type-getters = [ value-typename, value-typetag, value-type ]

    matches-any-type-of = (value, types-map) ->

      for type-getter in type-getters => typename = type-getter value ; return yes if types-map[ typename ] is yes
      no

    #

    count-required = (tokens) ->

      count = 0
      for t in tokens => count++ unless is-special-token t
      count

    count-required-from = (entries, from-index) ->

      count = 0
      for i from from-index to (array-size entries) - 1
        count++ unless is-special-token entries[i].token
      count

    needs-validation = (token-count, has-ellipsis) ->

      switch token-count
        | 0 => no
        | 1 => not has-ellipsis
        else yes

    item-count-mismatch-error-message = (has-ellipsis, item-name, required-count, actual-count, expected-count) ->

      expected = if has-ellipsis then "at least #required-count" else "#expected-count"
      if (has-ellipsis and actual-count < required-count) or (not has-ellipsis and actual-count isnt expected-count)
        "#expected #item-name, but has #actual-count"

    ##

    function-parameters = (sequence, descriptor-tokens, actual-item-names, sequence-name, descriptor, item-type-fn) ->

      actual-items-count = array-size actual-item-names
      descriptor-tokens-count = array-size descriptor-tokens

      item-index = token-index = 0

      loop

        break if item-index is actual-items-count and token-index is descriptor-tokens-count

        if item-index is actual-items-count

          token-index = skip-ellipsis-tokens descriptor-tokens, descriptor-tokens-count, token-index

          throw {sequence} `arg-must` "have at least #{ token-index + 1 } #sequence-name, but has #actual-items-count #{ as-per sequence-name, descriptor }" \
            if token-index < descriptor-tokens-count

          break

        else if token-index is descriptor-tokens-count

          throw {sequence} `arg-must` "not have trailing #sequence-name starting at index #item-index #{ as-per sequence-name, descriptor }"

        else

          { token, names-map } = descriptor-tokens[ token-index ]

          if is-special-token token

            [ item-index, token-index ] = handle-special-token actual-items-count, descriptor-tokens-count, item-index, token-index, token

          else

            actual-item-name = actual-item-names[ item-index ]

            throw {sequence} `arg-must` "have #sequence-name '#actual-item-name' matching token '#token' #{ as-per sequence-name, descriptor }" \
              unless names-map[ camel-case actual-item-name ] is yes

            if item-type-fn isnt void
              item-type-fn sequence, actual-item-name, token, sequence-name, descriptor

            item-index++ ; token-index++

    ##

    find-member-name = (object, names-map) ->

      for name of object
        return name if names-map[ camel-case name ] is yes
      void

    object-members = (object, descriptor-tokens, descriptor, matched-members) ->

      for { token, types-map, names-map } in descriptor-tokens

        continue if is-special-token token

        actual-name = find-member-name object, names-map

        throw {object} `arg-must` "have member matching token '#token' #{ as-per 'members', descriptor }" \
          if actual-name is void

        if types-map isnt void
          throw {object} `arg-must` "have member '#actual-name' being #{ any-of types-map } #{ as-per 'members', descriptor }" \
            unless object[ actual-name ] `matches-any-type-of` types-map

        matched-members[ actual-name ] = yes

    ##

    union-type = (value, { types-map }, descriptor) -> throw {value} `arg-must` "be #{ any-of types-map } #{ as-per 'type', descriptor }" unless value `matches-any-type-of` types-map

    #

    list-type = (list, { types-map }, descriptor) ->

      throw {list} `arg-must` "be an Array #{ as-per 'list', descriptor }" unless list |> is-array

      return if types-map is void

      for item, index in list

        throw {list} `arg-must` "have item at index #index being #{ any-of types-map } #{ as-per 'list', descriptor }" \
          unless item `matches-any-type-of` types-map

    #

    tuple-type = (tuple, { element-types-map }, descriptor) ->

      throw {tuple} `arg-must` "be an Array #{ as-per 'tuple', descriptor }" unless tuple |> is-array

      entries-count = array-size element-types-map
      has-ellipsis = ellipsis in [ e.token for e in element-types-map ]

      return unless needs-validation entries-count, has-ellipsis

      tuple-size = array-size tuple

      element-index = entry-index = 0

      loop

        return if element-index is tuple-size and entry-index is entries-count

        if element-index is tuple-size

          entry-index = skip-ellipsis-entries element-types-map, entries-count, entry-index

          throw {tuple} `arg-must` "have at least #{ entry-index + 1 } elements, but has #tuple-size #{ as-per 'tuple', descriptor }" \
            if entry-index < entries-count

          return

        else if entry-index is entries-count

          throw {tuple} `arg-must` "not have trailing elements starting at index #element-index #{ as-per 'tuple', descriptor }"

        else

          { token, types-map: entry-types-map } = element-types-map[ entry-index ]

          if is-special-token token

            if token is wildcard and element-index >= tuple-size
              throw {tuple} `arg-must` "have at least #{ element-index + 1 } elements, but has #tuple-size #{ as-per 'tuple', descriptor }"

            [ element-index, entry-index ] = handle-special-entry tuple-size, entries-count, element-index, entry-index, token

          else

            remaining-required = count-required-from element-types-map, entry-index + 1
            remaining-elements = tuple-size - element-index - 1

            throw {tuple} `arg-must` "have at least #{ element-index + 1 + remaining-required } elements, but has #tuple-size #{ as-per 'tuple', descriptor }" \
              if remaining-elements < remaining-required

            element = tuple[ element-index ]

            throw {tuple} `arg-must` "have element at index #element-index being #{ any-of entry-types-map } #{ as-per 'tuple', descriptor }" \
              unless element `matches-any-type-of` entry-types-map

            element-index++ ; entry-index++

    #

    parameter-type = (parameter-name, matched-parameters) ->

      actual-parameter-name = camel-case parameter-name
      matched-parameters[ actual-parameter-name ] = yes

    parameter-type-callback = (matched-parameters) -> (sequence, parameter-name, token, sequence-name, descriptor) ->
      parameter-type parameter-name, matched-parameters

    object-type = (object, { descriptor-tokens }, descriptor) ->

      throw {object} `arg-must` "be Object #{ as-per 'object', descriptor }" unless object |> is-object

      [ tokens-count, has-ellipsis ] = analyze-descriptor-tokens descriptor-tokens

      return unless needs-validation tokens-count, has-ellipsis

      strict = not has-ellipsis

      matched-members = {}

      object-members object, descriptor-tokens, descriptor, matched-members

      if strict

        for member-name of object

          throw {object} `arg-must` "not have unmatched member '#member-name' #{ as-per 'object', descriptor }" \
            unless matched-members[ member-name ] is yes

    #

    function-type = (fn, { descriptor-tokens }, descriptor) ->

      throw {fn} `arg-must` "be Function #{ as-per 'function', descriptor }" unless fn |> is-function

      [ tokens-count, has-ellipsis ] = analyze-descriptor-tokens descriptor-tokens

      return unless needs-validation tokens-count, has-ellipsis

      strict = not has-ellipsis

      fn-parameter-names = function-parameter-names fn
      matched-parameters = {}

      function-parameters fn, descriptor-tokens, fn-parameter-names, 'parameters', descriptor, parameter-type-callback matched-parameters

    ##

    parsed-descriptors-cache = {} ; get-parsed-descriptor = (descriptor) ->

      parsed-descriptors-cache[ descriptor ] => return .. unless .. is void
      type-descriptor descriptor => parsed-descriptors-cache[ descriptor ] := ..

    value-is-a = (value, descriptor) ->

      { kind } = parsed-descriptor = get-parsed-descriptor descriptor ; return value if kind is 'any'

      validate = (type-validator) -> type-validator value, parsed-descriptor, descriptor

      switch kind

        | 'type'     => validate union-type
        | 'list'     => validate list-type
        | 'tuple'    => validate tuple-type
        | 'object'   => validate object-type
        | 'function' => validate function-type

      value

    argument-is-a = (argument, descriptor) ->

      { argument-value } = argument-name-and-value argument

      try argument-value `value-is-a` descriptor
      catch error => throw arg-must argument, "be #descriptor", error

      argument-value

    {
      value-is-a, argument-is-a
    }
