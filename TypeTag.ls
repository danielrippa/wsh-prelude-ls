
  do ->

    { value-type, is-string } = dependency 'prelude.Type'
    { upper-case } = dependency 'prelude.String'

    capital-case = (string) -> [ initial, ...rest ] = string / '' ; [ (upper-case initial), (rest * '') ] * ''

    value-typetag = (value) ->

      typetag = {} |> (.to-string) |> (.call value) |> (.slice 8, -1)

      switch typetag

        | 'Object', 'Number' =>

          switch value

            | void => 'Void'
            | null => 'Null'

            else capital-case value-type value

        else typetag

    has-typetag = (typetag) ->

      (value) ->

        return null unless is-string typetag
        (value-typetag value) is typetag

    is-array = has-typetag 'Array'
    is-date = has-typetag 'Date'
    is-regexp = has-typetag 'RegExp'
    is-error = has-typetag 'Error'
    is-arguments = has-typetag 'Arguments'

    is-number-object = has-typetag 'Number'
    is-boolean-object = has-typetag 'Boolean'
    is-string-object  = has-typetag 'String'

    {
      value-typetag, has-typetag,
      is-array, is-date, is-regexp, is-error, is-arguments,
      is-boolean-object, is-number-object, is-string-object
    }