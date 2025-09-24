
  do ->

    regexp-flags = global: 'g', ignore-case: 'i', multiline: 'm'

    create-regexp = (expression, flags = regexp-flags.global) -> new RegExp expression, flags

    {
      regexp-flags,
      create-regexp
    }