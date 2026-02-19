
  do ->

    { is-function } = dependency 'prelude.Type'
    { trim-whitespace } = dependency 'prelude.Whitespace'
    { map-array-items } = dependency 'prelude.Array'

    decompose-function = (fn) ->

      return null unless is-function fn

      function-as-string = fn.to-string!

        body-start = ..index-of '{'
        body-end   = ..last-index-of '}'

        body-as-string = ..slice body-start + 1, body-end

        signature-as-string = ..slice 0, body-start

          parameters-start = ..index-of '('
          parameters-end   = ..last-index-of ')'

          parameters-as-string = ..slice parameters-start + 1, parameters-end

      parameter-names = if (trim-whitespace parameters-as-string) is ''

        then []
        else parameters-as-string / ',' |> map-array-items _, trim-whitespace

      { function-as-string, signature-as-string, parameter-names, parameters-as-string, body-as-string }

    function-parameter-names = (fn) -> return null unless is-function fn ; decompose-function fn |> (.parameter-names)

    function-as-string = (fn) -> return null unless is-function fn ; decompose-function fn |> (.function-as-string)

    {
      decompose-function,
      function-parameter-names,
      function-as-string
    }
