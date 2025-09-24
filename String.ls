
  do ->

    { create-regexp } = dependency 'prelude.RegExp'

    lower-case = (.to-lower-case!)

    upper-case = (.to-upper-case!)

    #

    trim-regexp = create-regexp '^ +| +$'

    trim = (.replace trim-regexp, '')

    #

    hyphen-or-underscore = '[-_]+'
    optional-single-char = '(.)?'

    find-separator = create-regexp "#hyphen-or-underscore#optional-single-char"

    remove-separator-capitalize-next-char = -> upper-case &1 ? ''

    camel-case = (.replace find-separator, remove-separator-capitalize-next-char)

    #

    add-hyphen-before-uppercase-regexp = create-regexp '([A-Z])'
    replace-spaces-underscores-regexp  = create-regexp '[\s_]+'

    remove-leading-hyphen-regexp = create-regexp '^-'

    underscores-regexp = create-regexp '_+'

    kebab-case = (string) ->

      string

        |> (.replace add-hyphen-before-uppercase-regexp, '-$1')
        |> (.to-lower-case!)
        |> (/ ' ')
        |> (* '-')
        |> (.replace underscores-regexp, '-')
        |> (.replace remove-leading-hyphen-regexp, '')

    {
      trim,
      lower-case, upper-case, camel-case, kebab-case
    }