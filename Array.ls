
  do ->

    { is-array } = dependency 'prelude.TypeTag'
    { is-function, is-string } = dependency 'prelude.Type'

    array-size = (array) -> return null unless is-array array ; array |> (.length)

    array-is-empty = (array) -> return null unless is-array array ; (array-size array) is 0

    array-isnt-empty = (array) -> return null unless is-array array ; not array-is-empty array

    identity = -> it
    tautology = -> yes

    map-array-items = (array, projection-fn = identity, predicate-fn = tautology) ->

      return null unless (is-array array) and (is-function projection-fn) and (is-function predicate-fn)

      [ (projection-fn item, index, array) for item, index in array when (predicate-fn item, index, array) ]

    keep-array-items = (array, predicate-fn) -> map-array-items array, void, predicate-fn

    drop-array-items = (array, predicate-fn) -> keep-array-items array, -> not predicate-fn ...

    array-as-string = (array, separator = '') -> array * "#separator"

    fold-array-items = (array, fn, initial-value) ->

      accumulator = initial-value
      for item, index in array => accumulator = fn accumulator, item, index, array
      accumulator

    find-array-index = (array, predicate-fn) ->

      return null unless (is-array array) and (is-function predicate-fn)

      for item, index in array
        return index if predicate-fn item, index, array

      -1

    {
      array-size,
      array-is-empty, array-isnt-empty,
      map-array-items, keep-array-items, drop-array-items,
      array-as-string,
      fold-array-items,
      find-array-index
    }