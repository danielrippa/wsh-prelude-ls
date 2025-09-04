do ->

    { value-type, is-empty-value, is-infinity, is-nan } = dependency 'prelude.reflection.ValueType'

    value-typetag = (value) ->

      typetag = {} |> (.to-string) |> (.call value) |> (.slice 8, -1)

      switch typetag

        | 'Object' => value-type value

        | 'Number' =>

          match value

            | is-infinity => fallthrough
            | is-nan =>

              value-type value

            else typetag

        else typetag

    is-array = -> (value-typetag it) is 'Array'
    is-date = -> (value-typetag it) is 'Date'
    is-regexp = -> (value-typetag it) is 'RegExp'

    {
      value-typetag,
      is-array, is-date, is-regexp
    }