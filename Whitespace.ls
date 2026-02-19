
  do ->

    { escape, one-or-more, starts-with, ends-with, string-join-with, string-replace-with, string-split-with, choice } = dependency 'prelude.RegExp'
    { punctuation-chars: { pipe } } = dependency 'prelude.Char'
    { is-string } = dependency 'prelude.Type'

    s-whitespace = one-or-more escape 's'

    leading-ws  = starts-with s-whitespace
    trailing-ws = ends-with   s-whitespace

    trim-ws-pattern = choice [ leading-ws, trailing-ws ]

    trim-whitespace = string-replace-with trim-ws-pattern, '', yes

    is-whitespace = (string) ->

      return null unless is-string string
      string |> trim-whitespace |> (== '')

    string-as-words = (string) ->

      return null unless is-string string
      string |> trim-whitespace |> string-split-with s-whitespace, yes

    {
      trim-whitespace,
      is-whitespace,
      string-as-words
    }