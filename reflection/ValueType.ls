  do ->

    is-null = (== null)
    is-void = (== void)

    is-empty-value = (value) ->

      match value

        | is-null => yes
        | is-void => yes

        else no

    has-type = (value, type) -> (typeof value) is type

    is-object = (value) ->

      return no unless value `has-type` 'object'

      not is-empty-value value

    primitive-types = <[ undefined boolean number string ]>

    is-primitive = -> return yes if is-null it ; typeof it in primitive-types

    is-nan = (!= it)

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

    is-string = _ `has-type` 'string'

    is-boolean = _ `has-type` 'boolean'

    is-function = _ `has-type` 'function'

    capitalized = -> "#{ it.char-at 0 .to-upper-case! }#{ it.slice 1 .to-lower-case! }"

    value-type = (value) ->

      match value

        | is-null => 'Null'
        | is-void => 'Void'

        | is-nan => 'NaN'
        | is-infinity => 'Infinity'

        | is-primitive => capitalized typeof value

        | is-object => 'Object'
        | is-function => 'Function'

    {
      is-null, is-void, is-empty-value, is-object,
      is-primitive,
      is-number, is-nan, is-infinity,
      is-string, is-boolean, is-function,
      value-type
    }