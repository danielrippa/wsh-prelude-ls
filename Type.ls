
  do ->

    value-type = (value) -> typeof value

    has-type = (value, type) ->

      return null unless (value-type type) is 'string'
      (value-type value) is type

    is-string = _ `has-type` 'string'
    is-boolean = _ `has-type` 'boolean'
    is-function = _ `has-type` 'function'

    is-null = (== null)
    is-void = (== void)

    is-defined = (value) -> value isnt void

    is-empty-value = (value) ->

      match value
        | is-null => yes
        | is-void => yes
        else no

    is-object = (value) ->

      return no unless value `has-type` 'object'
      not is-empty-value value

    is-nan = (value) -> value isnt value

    { POSITIVE_INFINITY: posinf, NEGATIVE_INFINITY: neginf } = Number

    is-infinity = (value) ->

      switch value
        | posinf, neginf => yes
        else no

    is-number = (value) ->

      return no unless value `has-type` 'number'

      match value
        | is-nan => no
        | is-infinity => no
        else yes

    primitive-types = <[ undefined boolean number string ]>

    is-primitive = (value) ->

      return yes if is-null value
      typeof value in primitive-types

    {
      value-type, has-type,
      is-string, is-number, is-boolean, is-function,
      is-null, is-void, is-defined, is-empty-value,
      is-object, is-nan, is-infinity, is-primitive
    }
