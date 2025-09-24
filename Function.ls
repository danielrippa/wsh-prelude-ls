
  do ->

    { map } = dependency 'prelude.Array'
    { trim } = dependency 'prelude.String'

    function-parameter-names = (fn) ->

      fn.to-string!

        start = ..index-of '('
        end   = ..index-of ')'

        names = ..slice start + 1, end

      if (names.index-of ',') isnt -1 then names |> (/ ',') |> map _ , trim else [ trim names ]

    {
      function-parameter-names
    }