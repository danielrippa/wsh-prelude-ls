
  do ->

    { punctuation-chars, control-chars } = dependency 'prelude.Char'
    { group, char-class, captured, one-or-more, zero-or-more, choice, sequence, entire, starts-with, ends-with, alpha-lower, alpha-upper, string-replace-with, is-matching, escape, follows } = dependency 'prelude.RegExp'
    { upper-case, lower-case, string-isnt-empty } = dependency 'prelude.String'

    { period: any-character, hyphen, underscore, space } = punctuation-chars

    captured-char = group any-character
    string-head = group starts-with any-character
    boundary-condition = group choice string-head, space
    separator-choice = choice hyphen, underscore, space
    separator-sequence = one-or-more separator-choice
    captured-separator = group separator-sequence
    word-joint-pattern = sequence captured-separator, captured-char
    word-head-pattern  = sequence boundary-condition, captured-char
    lowercase-word = one-or-more (char-class alpha-lower)
    alphanumeric = [ alpha-lower, alpha-upper ] * ''
    alphanumeric-word = one-or-more (char-class alphanumeric)
    uppercase-lowercase-transition = sequence (char-class alpha-upper), (char-class alpha-lower)

    separated-full-string = (separator) -> entire (sequence lowercase-word, (zero-or-more (sequence separator, lowercase-word)))

    kebab-full-string = separated-full-string hyphen
    camel-full-string = entire (sequence (char-class alpha-lower), (zero-or-more alphanumeric-word))
    pascal-full-string = entire (sequence (char-class alpha-upper), (zero-or-more alphanumeric-word))

    join-and-capitalize = (matched, p1, p2) -> if p2 isnt void then upper-case p2 else ''

    capitalize-at-boundary = (matched, p1, p2) -> if p2 isnt void then (if p1 isnt void then p1 else '') + upper-case p2 else ''

    mark-uppercase-boundaries = (separator) ->
      consecutive-capitals = sequence (group (char-class alpha-upper)), (follows uppercase-lowercase-transition)
      single-capital = group char-class alpha-upper
      
      mark-consecutive = string-replace-with consecutive-capitals, [ captured 1, separator ] * '', yes
      mark-single = string-replace-with single-capital, [ separator, captured 1 ] * '', yes
      
      mark-consecutive >> mark-single

    unify-separators = (separator) -> string-replace-with separator-sequence, separator, yes

    strip-separator = (pattern-fn, separator) -> string-replace-with (pattern-fn (escape separator)), '', yes

    strip-leading-separator = strip-separator starts-with, _

    strip-trailing-separator = strip-separator ends-with, _

    separated-case = (separator) ->

      (string) ->
      
        string
          |> mark-uppercase-boundaries separator
          |> lower-case
          |> unify-separators separator
          |> strip-leading-separator separator
          |> strip-trailing-separator separator

    transform-head-to-upper = (matched, capture-group) -> if string-isnt-empty capture-group then upper-case capture-group else ''

    word-after-space = sequence (group space), captured-char
    capitalize-after-space = (matched, space-char, char) -> if char isnt void then space-char + upper-case char else ''

    capitalize = string-replace-with string-head, transform-head-to-upper, yes
    capitalize-words = string-replace-with word-after-space, capitalize-after-space, yes
    join-words = string-replace-with word-joint-pattern, join-and-capitalize, yes

    kebab-case = separated-case hyphen
    snake-case = separated-case underscore
    space-case = separated-case space
    
    camel-case = kebab-case >> join-words
    pascal-case = camel-case >> capitalize
    constant-case = snake-case >> upper-case
    capital-case = space-case >> capitalize >> capitalize-words

    is-separated-case = (separator) -> is-matching (separated-full-string separator), yes
    
    is-kebab-case = is-separated-case hyphen
    is-camel-case = is-matching camel-full-string, yes
    is-pascal-case = is-matching pascal-full-string, yes

    {
      capitalize, capitalize-words,
      camel-case, pascal-case,
      separated-case,
      kebab-case, snake-case, space-case,
      constant-case, capital-case,
      is-separated-case,
      is-kebab-case, is-camel-case, is-pascal-case
    }




