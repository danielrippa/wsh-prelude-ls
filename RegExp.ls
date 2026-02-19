
  do ->

    { is-regexp } = dependency 'prelude.TypeTag'
    { is-string, is-boolean, is-function } = dependency 'prelude.Type'
    { is-array } = dependency 'prelude.TypeTag'
    { upper-case } = dependency 'prelude.String'
    { punctuation-chars } = dependency 'prelude.Char'
    { round-brackets, square-brackets } = dependency 'prelude.Circumfix'
    { array-as-string } = dependency 'prelude.Array'

    { caret, question, colon, asterisk: any-amount, plus: at-least-one, pipe, backslash, dollar, exclamation, equals } = punctuation-chars

    regexp-flags = global: 'g', ignore-case: 'i', multiline: 'm'

    create-regexp = (expression, flags = regexp-flags.global) ->

      return null unless (is-string expression) and (is-string flags)
      new RegExp expression, flags

    as-pattern = (value, use-regexp, flags) -> 
      if use-regexp 
        then create-regexp value, flags
        else value

    string-split-with = (delimiter = '', use-regexp, flags) ->

      (string) ->

        return null unless (is-string delimiter) and (is-string string)
        if flags isnt void
          return null unless is-string flags
        if use-regexp isnt void
          return null unless is-boolean use-regexp

        string.split as-pattern delimiter, use-regexp, flags

    string-join-with = (delimiter = '') ->

      (strings) ->

        return null unless (is-array strings) and (is-string delimiter)
        strings.join delimiter

    string-replace-with = (expression, replacement = '', use-regexp, flags) ->

      (string) ->

        pattern = as-pattern expression, use-regexp, flags

        switch
          | not is-string string => null
          | replacement isnt void and not ((is-string replacement) or (is-function replacement)) => null
          | flags isnt void and not is-string flags => null
          | use-regexp isnt void and not is-boolean use-regexp => null
          | pattern is null => null
          else string.replace pattern, replacement

    is-matching = (expression, use-regexp, flags) ->

      (string) ->

        return null unless is-string string
        pattern = as-pattern expression, use-regexp, flags
        string |> (.match pattern) |> (!= null)

    is-not-matching = (expression, use-regexp, flags) ->

      (string) ->

        return null unless is-string string
        not (is-matching expression, use-regexp, flags) string

    non-capturing-marker = [ question, colon ] * ''

    non-capturing-group = (pattern) ->

      return null unless is-string pattern
      [ non-capturing-marker, pattern ] |> array-as-string |> group

    quantify = (marker) -> (pattern) ->

      return null unless (is-string marker) and (is-string pattern)
      [ (non-capturing-group pattern), marker ] |> array-as-string

    zero-or-more = quantify any-amount
    one-or-more  = quantify at-least-one
    optional = quantify question

    alpha-lower = 'a-z' ; alpha-upper = upper-case alpha-lower

    digits = '0-9'

    alphabetic = [ alpha-lower, alpha-upper ] * ''
    alphanumeric = [ alphabetic, digits ] * ''

    hex-lower = 'a-f' ; hex-upper = upper-case hex-lower
    hex-alphabetic = [ hex-lower, hex-upper ] * ''
    hex-alphanumeric = [ digits, hex-alphabetic ] * ''

    char-class = (pattern) ->

      return null unless is-string pattern
      square-brackets pattern

    negated-char-class = (pattern) ->

      return null unless is-string pattern
      [ caret, pattern ] * '' |> square-brackets

    group = (pattern) ->

      return null unless is-string pattern
      round-brackets pattern

    combine = (separator) -> (...patterns) ->

      return null unless is-string separator
      patterns |> (string-join-with separator) |> non-capturing-group

    sequence = combine ''

    choice = combine pipe

    escape = (pattern) ->

      return null unless is-string pattern
      [ backslash, pattern ] * ''

    starts-with = sequence caret, _
    ends-with   = sequence _, dollar

    entire = (...patterns) -> (sequence ...patterns) |> starts-with |> ends-with

    word-boundary = escape 'b' ; non-word-boundary = escape 'B'

    starts-at-boundary = sequence word-boundary, _
    ends-at-boundary   = sequence _, word-boundary

    isolated = _ |> starts-at-boundary |> ends-at-boundary

    lookahead = (qualifier) -> (pattern) ->

      return null unless (is-string qualifier) and (is-string pattern)
      operator = [ question, qualifier ] * ''
      sequence (escape operator), pattern

    follows = lookahead equals
    not-follows = lookahead exclamation

    captured = (index) -> [ dollar, index ] |> array-as-string

    {
      regexp-flags, create-regexp,
      string-split-with, string-join-with, string-replace-with,
      is-matching, is-not-matching,
      alpha-lower, alpha-upper, alphabetic, digits, alphanumeric,
      hex-lower, hex-upper, hex-alphabetic, hex-alphanumeric,
      char-class, negated-char-class,
      group, non-capturing-group
      zero-or-more, one-or-more, optional
      combine, sequence, choice,
      escape,
      starts-with, ends-with, entire, isolated, captured,
      follows, not-follows
    }