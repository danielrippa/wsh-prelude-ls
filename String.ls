
  do ->

    { create-regexp } = dependency 'prelude.RegExp'

    trim-regexp = create-regexp '^ +| +$'

    trim = (.replace trim-regexp, '')

    #

    camel-case-regexp = create-regexp '[-_](.)'

    camel-case = (.replace camel-case-regexp, -> &1.to-upper-case!)

    #

    add-hyphen-before-uppercase-regexp = create-regexp '([A-Z])'
    replace-spaces-underscores-regexp  = create-regexp '[\s_]+'

    remove-leading-hyphen-regexp = create-regexp '^-'

    underscores-regexp = create-regexp '_+'

    print = -> WScript.Echo it ; it

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
      camel-case, kebab-case
    }