
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

    call-function-until = (is-done-fn, step-fn, initial-state) ->

      for fn in [ is-done-fn, step-fn ] => return null unless is-function fn

      state = initial-state
      until is-done-fn state => state = step-fn state
      state

    call-function-while = (should-continue-fn, step-fn, initial-state) ->

      for fn in [ should-continue-fn, step-fn ] => return null unless is-function fn

      state = initial-state
      while shuld-continue-fn state => state = step-fn state
      state

    call-function = (step-fn) ->

      return null unless is-function step-fn

      until: (is-done-fn) -> (initial-state) -> call-function-until is-done-fn, step-fn, initial-state
      while: (should-continue-fn) -> (step-fn) -> (initial-value) -> call-function-while should-continue-fn, step-fn, initial-value

    {
      decompose-function,
      function-parameter-names,
      function-as-string,
      call-function
    }
