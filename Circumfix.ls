
  do ->

    { is-string } = dependency 'prelude.Type'

    circumfix = (stem, affixes) ->

      return null unless (is-string stem)
      [ prefix, suffix = prefix ] = affixes ; return null unless (is-string prefix) and (is-string suffix)
      [ prefix, stem, suffix ] * ''

    wrap = -> circumfix _ , it / ''

    [ curly-brackets, square-brackets, round-brackets, angle-brackets ] = [ (wrap chars) for chars in '{} [] () <>' / ' ' ]

    [ single-quotes, double-quotes ] = [ (wrap chars) for chars in <[ ' " ]> ]

    {
      circumfix,
      curly-brackets, square-brackets, round-brackets, angle-brackets,
      single-quotes, double-quotes
    }