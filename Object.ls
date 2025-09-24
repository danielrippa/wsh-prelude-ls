
  do ->

    { is-object } = dependency 'prelude.reflection.IsA'

    object-member-names = (object) -> return null unless is-object object ; [ (member-name) for member-name of object ]

    {
      object-member-names
    }