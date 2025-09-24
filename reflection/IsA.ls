
  do ->

    { value-type, is-string, is-number, is-boolean, is-function, is-object, is-null, is-void, is-nan, is-infinity } = dependency 'prelude.reflection.ValueType'
    { value-typetag, is-array, is-date, is-regexp } = dependency 'prelude.reflection.TypeTag'
    { value-typename, value-has-typename } = dependency 'prelude.reflection.TypeName'

    is-a = (value, descriptor) ->

      return yes if (value-typename value) is descriptor
      return yes if (value-typetag value) is descriptor
      return yes if (value-type value) is descriptor

      no

    matches-any = (value, types-map) ->

      return yes if types-map[ value-typename value ] is yes
      return yes if types-map[ value-typetag value ] is yes
      return yes if types-map[ value-type value ] is yes

      no

    is-any-of = (value, descriptors) -> return null unless is-array descriptors ; value `matches-any` { [ type, yes ] for type in descriptors }

    {
      is-a, is-any-of, matches-any,
      is-array, is-date, is-regexp,
      is-string, is-number, is-boolean, is-function, is-object,
      is-null, is-void, is-nan, is-infinity
    }

