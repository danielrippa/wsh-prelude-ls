do ->

    { value-type, is-string, is-number, is-boolean, is-function, is-object, is-null, is-void, is-nan, is-infinity } = dependency 'prelude.reflection.ValueType'
    { value-typetag, is-array, is-date, is-regexp } = dependency 'prelude.reflection.TypeTag'
    { value-typename, value-has-typename } = dependency 'prelude.reflection.TypeName'

    is-a = (value, descriptor) ->

      return yes if (value-typename value) is descriptor
      return yes if (value-typetag value) is descriptor
      return yes if (value-type value) is descriptor

      no

    is-any-of = (value, descriptors) ->

      return null unless is-array descriptors

      types-map = {} ; for type in descriptors => types-map[ type ] = yes
      types-map[ value-typename value ] or types-map[ value-typetag value ] or types-map[ value-type value ]

    {
      is-a, is-any-of,
      is-array, is-date, is-regexp,
      is-string, is-number, is-boolean, is-function, is-object,
      is-null, is-void, is-nan, is-infinity
    }