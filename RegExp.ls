
  do ->

    flags = global: 'g'

    create-regexp = (pattern, flag = flags.global) -> new RegExp pattern, flag

    {
      create-regexp
    }