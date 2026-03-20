
  do ->

    { is-function } = dependency 'prelude.Type'

    perform-until = (is-done, step-fn, initial-state) ->

      for fn in [ is-done, step-fn ] => return null unless is-function fn

      state = initial-state
      until is-done state => state = step-fn state
      state

    perform-while = (should-continue-fn, step-fn, initial-state) ->

      for fn in [ should-continue-fn, step-fn ] => return null unless is-function fn

      state = initial-state
      while should-continue-fn state => state = step-fn state
      state

    perform = (step-fn) ->

      return null unless is-function step-fn

      until: (is-done-fn) -> (initial-state) -> perform-until is-done-fn, step-fn, initial-state
      while: (should-continue-fn) -> (step-fn) -> (initial-value) -> perform-while should-continue-fn, step-fn, initial-value

    {
      perform-until, perform-while,
      perform
    }