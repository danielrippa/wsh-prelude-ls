
  do ->

    { value-type, is-function, is-object } = dependency 'prelude.Type'
    { value-typetag, is-array } = dependency 'prelude.TypeTag'
    { value-typename } = dependency 'prelude.TypeName'
    { create-argument-error: arg-error, create-argument-type-error: arg-must-be, create-argument-requirement-error: arg-must } = dependency 'prelude.error.Argument'
    { type-descriptor } = dependency 'prelude.reflection.TypeDescriptor'
    { object-member-names } = dependency 'prelude.Object'
    { array-size, fold-array-items, keep-array-items, drop-array-items, find-array-index } = dependency 'prelude.Array'
    { function-parameter-names } = dependency 'prelude.Function'
    { kebab-case, camel-case } = dependency 'prelude.Case'
    { punctuation-chars: { period, pipe } } = dependency 'prelude.Char'
    { string-split-with } = dependency 'prelude.RegExp'

    { value-as-string } = dependency 'prelude.Value'

    join-with-comma = (* ', ')
    split-by-pipe = string-split-with pipe

    ellipsis = "#period" * 3

    matches-any = (value, types-map) ->

      return yes if types-map[ value-typename value ] is yes
      return yes if types-map[ value-typetag value ] is yes
      return yes if types-map[ value-type value ] is yes

      no

    is-any-of = (value, descriptors) -> value `matches-any-type` { [ type, yes ] for type in descriptors }

    any-of = (tokens) ->
      prefix = if (array-size tokens) is 1 then '' else 'any of '
      [ prefix, tokens * ', ' ] * ''

    as-per = (kind, descriptor) -> "as per #kind '#descriptor'"

    #

    union-type = (value, { kind, types-map }, descriptor) ->

      throw {value} `arg-must-be` "#{ any-of object-member-names types-map } #{ as-per kind, descriptor }" unless value `matches-any` types-map
      value

    #

    invalid-item-type-error-message = (list, kind, types-map, type-names, descriptor, index) -> {list} `arg-must` "have element at index #index being #{ any-of type-names } #{ as-per kind, descriptor }"

    validate-list-item-type = (list, kind, types-map, type-names, descriptor, index, item) ->

      throw invalid-item-type-error-message list, kind, types-map, type-names, descriptor, index unless item `matches-any` types-map

    list-type = (list, { kind, types-map }, descriptor) ->

      throw {list} `arg-must-be` "Array #{ as-per kind, descriptor }" unless is-array list

      type-names = object-member-names types-map

      for item, index in list => validate-list-item-type list, kind, types-map, type-names, descriptor, index, item

      list

    #

    iterate-until-stable = (step-function, initial-state) ->

      current-state = initial-state

      loop

        next-state = step-function current-state

        { element-index: next-element, type-index: next-type } = next-state
        { element-index: current-element, type-index: current-type } = current-state

        break if next-element is current-element and next-type is current-type

        current-state = next-state

      current-state

    skip-items-for-ellipsis = (total-items, total-types, current-item-index, ellipsis-type-index) ->

      types-after-ellipsis = total-types - ellipsis-type-index
      last-item-index = total-items - types-after-ellipsis

      if current-item-index > last-item-index then current-item-index else last-item-index

    count-non-ellipsis-tokens = (tokens) ->

      is-special-token = (token) -> token is ellipsis or token is '?'
      tokens |> drop-array-items _, is-special-token |> array-size

    tuple-size-error = (tuple, expected, actual, strict, kind, descriptor) ->

      qualifier = if strict then '' else 'at least '
      {tuple} `arg-must` "have #qualifier#expected items, but has #actual #{ as-per kind, descriptor }"

    validate-tuple-has-minimum-size = (tuple, types, kind, descriptor) ->

      has-ellipsis = ellipsis in types
      has-optional = '?' in types
      strict = not has-ellipsis and not has-optional
      elements-count = array-size tuple
      expected-size = if strict then array-size types else count-non-ellipsis-tokens types

      throw tuple-size-error tuple, expected-size, elements-count, strict, kind, descriptor if elements-count < expected-size

    trailing-elements-error = (tuple, descriptor, element-index) ->

      {tuple} `arg-must` "not have trailing elements starting at index #element-index #{ as-per 'tuple', descriptor }"

    is-not-optional-or-ellipsis = (token) -> token isnt '?' and token isnt ellipsis

    skip-optional-and-ellipsis-types = (types, type-index) ->

      remaining-types = types.slice type-index
      first-required-offset = find-array-index remaining-types, is-not-optional-or-ellipsis

      if first-required-offset is -1 then types.length else type-index + first-required-offset

    is-optional-type = (token) -> token is '?'

    is-ellipsis-type = (token) -> token is ellipsis

    parse-union-type = (token) -> { [ type, yes ] for type in split-by-pipe token }

    element-type-error = (tuple, element-index, expected-types, descriptor) ->

      {tuple} `arg-must` "have element at index #element-index being #{ any-of object-member-names expected-types } #{ as-per 'tuple', descriptor }"

    validate-element-matches-type = (tuple, element-index, type-token, descriptor) ->

      return if is-ellipsis-type type-token
      return if is-optional-type type-token

      element = tuple[element-index]
      expected-types = parse-union-type type-token

      throw element-type-error tuple, element-index, expected-types, descriptor unless element `matches-any` expected-types

    advance-to-next-element = (element-index, type-index) ->

      { element-index: element-index + 1, type-index: type-index + 1, prev-ellipsis: no }

    advance-past-ellipsis = (elements-count, types-count, element-index, type-index) ->

      new-element-index = skip-items-for-ellipsis elements-count, types-count, element-index, type-index + 1

      { element-index: new-element-index, type-index: type-index + 1, prev-ellipsis: yes }

    validate-and-advance = (tuple, types, descriptor, element-index, type-index) ->

      validate-element-matches-type tuple, element-index, types[type-index], descriptor

      advance-to-next-element element-index, type-index

    both-done = (element-index, elements-count, type-index, types-count) ->

      element-index is elements-count and type-index is types-count

    elements-done = (element-index, elements-count) -> element-index is elements-count

    types-done = (type-index, types-count) -> type-index is types-count

    handle-elements-done = (types, type-index, validation-state) ->

      new-type-index = skip-optional-and-ellipsis-types types, type-index

      validation-state <<< { type-index: new-type-index, prev-ellipsis: no }

    handle-types-done = (tuple, descriptor, element-index) ->

      throw trailing-elements-error tuple, descriptor, element-index

    handle-optional-type = (element-index, type-index) ->

      advance-to-next-element element-index, type-index

    handle-ellipsis-type = (elements-count, types-count, element-index, type-index, strict) ->

      return advance-to-next-element element-index, type-index if strict

      advance-past-ellipsis elements-count, types-count, element-index, type-index

    handle-regular-type = (tuple, types, descriptor, element-index, type-index) ->

      validate-and-advance tuple, types, descriptor, element-index, type-index

    step-tuple-validation = (tuple, types, descriptor) ->

      strict = ellipsis not in types
      elements-count = array-size tuple
      types-count = array-size types

      (validation-state) ->

        { element-index, type-index } = validation-state

        return validation-state if both-done element-index, elements-count, type-index, types-count

        return handle-elements-done types, type-index, validation-state if elements-done element-index, elements-count

        handle-types-done tuple, descriptor, element-index if types-done type-index, types-count

        type-token = types[type-index]

        switch

          | is-optional-type type-token => handle-optional-type element-index, type-index

          | is-ellipsis-type type-token => handle-ellipsis-type elements-count, types-count, element-index, type-index, strict

          else handle-regular-type tuple, types, descriptor, element-index, type-index

    validate-tuple-elements = (tuple, types, descriptor) ->

      initial-state = { element-index: 0, type-index: 0, prev-ellipsis: no }

      step-function = step-tuple-validation tuple, types, descriptor

      iterate-until-stable step-function, initial-state

    tuple-type = (tuple, { kind, types }, descriptor) ->

      throw {tuple} `arg-must-be` "Array #{ as-per kind, descriptor }" unless is-array tuple

      validate-tuple-has-minimum-size tuple, types, kind, descriptor

      validate-tuple-elements tuple, types, descriptor

      tuple

    #

    count-non-ellipsis-members = (members) ->

      members |> drop-array-items _, (.name) >> (== ellipsis) |> array-size

    object-members-count-error = (object, expected, actual, strict, kind, descriptor) ->

      qualifier = if strict then '' else 'at least '
      {object} `arg-must` "have #qualifier#expected members, but has #actual #{ as-per kind, descriptor }"

    validate-object-has-minimum-members = (object, members, kind, descriptor) ->

      strict = ellipsis not in [ member.name for member in members ]

      return if strict

      minimum-members = count-non-ellipsis-members members
      members-count = object-member-names object |> array-size

      throw object-members-count-error object, minimum-members, members-count, strict, kind, descriptor if members-count < minimum-members

    missing-member-error = (object, member-name, descriptor) ->

      {object} `arg-must` "have member '#member-name' #{ as-per 'object', descriptor }"

    member-type-error = (object, member-name, expected-types, descriptor) ->

      {object} `arg-must` "have member '#member-name' being #{ any-of object-member-names expected-types } #{ as-per 'object', descriptor }"

    validate-member-matches-type = (object, member-name, member-spec, descriptor) ->

      { types-map } = member-spec

      return if types-map is null

      try
        camel-name = camel-case member-name
      catch e
        # camel-case has a bug in ES3, skip type validation
        return
      
      return if camel-name is null
      
      member-value = object[camel-name]

      throw member-type-error object, member-name, types-map, descriptor unless member-value `matches-any` types-map

    is-optional-member = (.name) >> (== '?')

    is-ellipsis-member = (.name) >> (== ellipsis)

    build-member-lookup = (object) ->

      result = {}
      for key of object
        kebab-key = kebab-case key
        if kebab-key isnt null
          result[kebab-key] = yes
      result

    is-processable-member = (.name) >> (name) -> name isnt '?' and name isnt ellipsis

    filter-processable-members = (members) ->

      members |> keep-array-items _, is-processable-member

    validate-member-exists = (object, member-name, member-lookup, descriptor) ->

      throw missing-member-error object, member-name, descriptor unless member-lookup[member-name] is yes

    validate-member = (object, member-spec, member-lookup, descriptor, matched-members) ->

      { name } = member-spec

      validate-member-exists object, name, member-lookup, descriptor

      validate-member-matches-type object, name, member-spec, descriptor

      matched-members <<< { (name): yes }

    validate-required-members = (object, members, member-lookup, descriptor) ->

      processable-members = filter-processable-members members

      accumulate-validated-member = (matched-members, member-spec) ->

        validate-member object, member-spec, member-lookup, descriptor, matched-members

      fold-array-items processable-members, accumulate-validated-member, {}

    find-unmatched-members = (member-lookup, matched-members) ->

      [ member-name for member-name of member-lookup when matched-members[member-name] isnt yes ]

    trailing-members-error = (object, descriptor, unmatched-count) ->

      {object} `arg-must` "not have #unmatched-count unmatched members #{ as-per 'object', descriptor }"

    validate-no-trailing-members = (object, members, unmatched-members, descriptor) ->

      strict = ellipsis not in [ member.name for member in members ]

      return unless strict

      unmatched-count = array-size unmatched-members

      throw trailing-members-error object, descriptor, unmatched-count if unmatched-count > 0

    object-type = (object, { kind, members, strict }, descriptor) ->

      throw {object} `arg-must-be` "Object #{ as-per kind, descriptor }" unless is-object object

      validate-object-has-minimum-members object, members, kind, descriptor

      member-lookup = build-member-lookup object

      matched-members = validate-required-members object, members, member-lookup, descriptor

      unmatched-members = find-unmatched-members member-lookup, matched-members

      validate-no-trailing-members object, members, unmatched-members, descriptor

      object


    #

    count-non-ellipsis-params = (params) ->

      is-special-token = (param) -> param.name is ellipsis or param.name is '?'
      params |> drop-array-items _, is-special-token |> array-size

    function-params-count-error = (fn, expected, actual, strict, kind, descriptor) ->

      qualifier = if strict then '' else 'at least '
      {fn} `arg-must` "have #qualifier#expected parameters, but has #actual #{ as-per kind, descriptor }"

    validate-function-has-minimum-params = (fn, params, kind, descriptor) ->

      has-ellipsis = ellipsis in [ param.name for param in params ]
      has-optional = '?' in [ param.name for param in params ]
      strict = not has-ellipsis and not has-optional
      
      params-count = function-parameter-names fn |> array-size
      required-params = count-non-ellipsis-params params
      
      if strict
        throw function-params-count-error fn, required-params, params-count, strict, kind, descriptor if params-count isnt required-params
      else
        throw function-params-count-error fn, required-params, params-count, strict, kind, descriptor if params-count < required-params

    param-type-error = (fn, param-name, param-index, expected-types, descriptor) ->

      {fn} `arg-must` "have parameter '#param-name' at index #param-index being #{ any-of object-member-names expected-types } #{ as-per 'function', descriptor }"

    validate-param-matches-type = (fn, param-name, param-index, param-spec, descriptor, argument) ->

      { types-map } = param-spec

      return if types-map is null

      param-value = argument[param-name]

      throw param-type-error fn, param-name, param-index, types-map, descriptor unless param-value `matches-any` types-map

    is-not-optional-or-ellipsis-param = (.name) >> (name) -> name isnt '?' and name isnt ellipsis

    skip-optional-and-ellipsis-params = (params, param-index) ->

      remaining-params = params.slice param-index
      first-required-offset = find-array-index remaining-params, is-not-optional-or-ellipsis-param

      if first-required-offset is -1 then params.length else param-index + first-required-offset

    params-done = (param-index, params-count) -> param-index is params-count

    names-done = (name-index, names-count) -> name-index is names-count

    both-params-done = (param-index, params-count, name-index, names-count) ->

      params-done param-index, params-count and names-done name-index, names-count

    handle-params-done = (params, param-index, validation-state) ->

      new-param-index = skip-optional-and-ellipsis-params params, param-index

      validation-state <<< { param-index: new-param-index }

    trailing-params-error = (fn, descriptor, name-index) ->

      {fn} `arg-must` "not have trailing parameters starting at index #name-index #{ as-per 'function', descriptor }"

    handle-names-done = (fn, descriptor, name-index) ->

      throw trailing-params-error fn, descriptor, name-index

    is-optional-param = (.name) >> (== '?')

    is-ellipsis-param = (.name) >> (== ellipsis)

    advance-to-next-param = (param-index, name-index) ->

      { param-index: param-index + 1, name-index: name-index + 1 }

    skip-params-for-ellipsis = (total-names, total-params, current-name-index, ellipsis-param-index) ->

      params-after-ellipsis = total-params - ellipsis-param-index
      last-name-index = total-names - params-after-ellipsis

      if current-name-index > last-name-index then current-name-index else last-name-index

    advance-past-param-ellipsis = (names-count, params-count, name-index, param-index) ->

      new-name-index = skip-params-for-ellipsis names-count, params-count, name-index, param-index + 1

      { param-index: param-index + 1, name-index: new-name-index }

    validate-and-advance-param = (fn, param-names, params, descriptor, argument, param-index, name-index) ->

      param-name = param-names[name-index]
      param-spec = params[param-index]

      validate-param-matches-type fn, param-name, name-index, param-spec, descriptor, argument

      advance-to-next-param param-index, name-index

    handle-optional-param = (param-index, name-index) ->

      advance-to-next-param param-index, name-index

    handle-ellipsis-param = (names-count, params-count, name-index, param-index, strict) ->

      return advance-to-next-param param-index, name-index if strict

      advance-past-param-ellipsis names-count, params-count, name-index, param-index

    handle-regular-param = (fn, param-names, params, descriptor, argument, param-index, name-index) ->

      validate-and-advance-param fn, param-names, params, descriptor, argument, param-index, name-index

    step-function-validation = (fn, param-names, params, descriptor, argument) ->

      strict = ellipsis not in [ param.name for param in params ]
      names-count = array-size param-names
      params-count = array-size params

      (validation-state) ->

        { param-index, name-index } = validation-state

        return validation-state if both-params-done param-index, params-count, name-index, names-count

        return handle-params-done params, param-index, validation-state if params-done param-index, params-count

        handle-names-done fn, descriptor, name-index if names-done name-index, names-count

        param-spec = params[param-index]

        switch

          | is-optional-param param-spec => handle-optional-param param-index, name-index

          | is-ellipsis-param param-spec => handle-ellipsis-param names-count, params-count, name-index, param-index, strict

          else handle-regular-param fn, param-names, params, descriptor, argument, param-index, name-index

    validate-function-params = (fn, param-names, params, descriptor, argument) ->

      initial-state = { param-index: 0, name-index: 0 }

      step-function = step-function-validation fn, param-names, params, descriptor, argument

      iterate-until-stable step-function, initial-state

    function-type = (fn, { kind, params }, descriptor) ->

      throw {fn} `arg-must-be` "Function #{ as-per kind, descriptor }" unless is-function fn

      validate-function-has-minimum-params fn, params, kind, descriptor

      fn

    #

    parsed-type-descriptors = {}

    get-parsed-descriptor = (descriptor) ->

      cached = parsed-type-descriptors[ descriptor ] ; return cached if cached isnt void

      type-descriptor descriptor => parsed-type-descriptors[ descriptor ] := ..

    get-type-validator = ({ kind }) ->

      switch kind

        | 'type' => union-type
        | 'list' => list-type
        | 'tuple' => tuple-type
        | 'object' => object-type
        | 'function' => function-type

    type = (descriptor, value) ->

      { kind } = parsed-descriptor = get-parsed-descriptor descriptor ; return value if kind is 'any'

      (get-type-validator parsed-descriptor) value, parsed-descriptor, descriptor

    {
      type
    }