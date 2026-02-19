
  do ->

    { is-string, is-number } = dependency 'prelude.Type'

    string-size = (string) ->

      return null unless is-string string
      string |> (.length)

    string-is-empty = (string) ->

      return null unless is-string string
      (string-size string) is 0

    string-isnt-empty = (string) ->

      return null unless is-string string
      not string-is-empty string

    string-repeat = (string, count) ->

      return null unless (is-string) and (is-number count)
      new Array count + 1 |> (.join string)

    string-starts-with = (haystack, needle) ->

      return null unless (is-string haystack) and (is-string needle)
      haystack |> (.index-of needle) |> (== 0)

    string-ends-with = (haystack, needle) ->

      return null unless (is-string haystack) and (is-string needle)
      haystack |> (.last-index-of needle) |> (!= -1)

    string-contains = (haystack, needle) ->

      return null unless (is-string haystack) and (is-string needle)
      haystack |> (.index-of needle) |> (!= -1)

    upper-case = (string) ->

      return null unless is-string string
      string |> (.to-upper-case!)

    lower-case = (string) ->

      return null unless is-string string
      string |> (.to-lower-case!)

    {
      string-size,
      string-is-empty, string-isnt-empty,
      string-repeat,
      string-starts-with, string-ends-with, string-contains,
      upper-case, lower-case
    }