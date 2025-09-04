
  do ->

    map = (array, fn) -> [ (fn item, index, array) for item, index in array ]

    filter = (array, predicate) -> [ (item) for item, index in array when predicate item, index, array ]

    {
      map, filter
    }