
  do ->

    { is-object, is-array } = dependency 'prelude.reflection.IsA'
    { map } = dependency 'prelude.Array'
    { camel-case } = dependency 'prelude.String'

    object-member-names = (object) -> return null unless is-object object ; [ (member-name) for member-name of object ]

    object-missing-members = (object, member-names) ->

      return null unless is-object objec ; return null unless is-array member-names

      required-member-names = map member-names, camel-case

      missing-member-names = []
      for member-name of object => unless member-name in required-member-names => missing-member-names.push member-name

      missing-member-names

    {
      object-member-names, object-missing-members
    }