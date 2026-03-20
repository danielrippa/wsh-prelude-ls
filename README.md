# prelude

A functional utility library for WSH JScript (ES3), written in LiveScript.

WSH JScript gives you almost nothing — no stack traces, no type errors, no module system. This library builds all of that from scratch, giving you a proper foundation for scripting on Windows without the usual pain.

---

## Modules

### Core Types

**`prelude.Type`**
Primitive type checks: `is-string`, `is-number`, `is-boolean`, `is-function`, `is-object`, `is-null`, `is-void`, `is-nan`, `is-infinity`, `is-primitive`. The foundation everything else builds on.

**`prelude.TypeTag`**
`Object.prototype.toString`-based type tags. More precise than `typeof` — distinguishes `Array`, `Date`, `RegExp`, `Error`, `Arguments`, boxed primitives, `Null`, and `Void`.

**`prelude.TypeName`**
Resolves a value's human-readable type name. Uses constructor name for objects, `.name` for errors, typetag otherwise.

**`prelude.Value`**
Serializes any value to a readable string. `value-as-string` gives you `'hello'`, `[1, 2, 3]`, `{ a: 1 }`, `(x, y) -> {}`. `typed-value-as-string` prefixes with the type: `<String> 'hello'`.

---

### Collections

**`prelude.Array`**
ES3-safe array utilities: `map-array-items`, `keep-array-items`, `drop-array-items`, `fold-array-items`, `array-item-index`, `any-array-item-matches`, `array-sort`, `array-size`, `array-is-empty`.

**`prelude.Object`**
`object-member-names`, `object-member-values`, `object-constructor-name`.

---

### Strings

**`prelude.String`**
`string-size`, `string-is-empty`, `string-repeat`, `string-starts-with`, `string-ends-with`, `string-contains`, `upper-case`, `lower-case`.

**`prelude.Whitespace`**
`trim-whitespace`, `is-whitespace`, `string-as-words`.

**`prelude.Char`**
Named character constants. `punctuation-chars` covers everything from `space` to `tilde`. `control-chars` covers C0 and C1 control codes. No magic strings.

**`prelude.Circumfix`**
Wraps strings in bracket pairs: `angle-brackets`, `round-brackets`, `square-brackets`, `curly-brackets`, `single-quotes`, `double-quotes`. Also the general `circumfix` for custom affixes.

**`prelude.Case`**
Full case conversion: `camel-case`, `pascal-case`, `kebab-case`, `snake-case`, `space-case`, `constant-case`, `capital-case`. Also `is-kebab-case`, `is-camel-case`, `is-pascal-case`.

---

### RegExp

**`prelude.RegExp`**
A composable regexp builder. Construct patterns from named combinators — `sequence`, `choice`, `one-or-more`, `zero-or-more`, `optional`, `char-class`, `group`, `captured`, `follows`, `entire`, etc. — then use `string-replace-with`, `string-split-with`, `is-matching` to apply them.

---

### Functions & Iteration

**`prelude.Function`**
`function-parameter-names`, `function-as-string`, `decompose-function`. Also `call-function` for structured iteration with `.until` and `.while`.

**`prelude.Iteration`**
`perform-until`, `perform-while`, `perform` — same pattern as `call-function` but without the function decomposition overhead.

---

### Reflection

**`prelude.reflection.TypeDescriptor`**
Parses type descriptor strings into structured ASTs. Supports:
- `<Number|String>` — union types
- `[*:Number]` — typed lists
- `[Number String]` — tuples
- `{ name:String age:Number }` — object shapes
- `(x y z)` — function signatures
- Wildcards `?` and ellipsis `...` in sequences

**`prelude.reflection.Argument`**
Unpacks single-property argument objects `{ argName: value }` into `{ argument-name, argument-value }`. Used throughout the error system to produce named argument errors.

**`prelude.reflection.IsA`**
Runtime type validation. Two entry points:

- `value-is-a value, '<Number>'` — validates a plain value, throws on mismatch
- `argument-is-a { myArg: value }, '<Number>'` — validates a named argument, throws a named error

Validates union types, lists, tuples, object shapes, and function signatures against parsed descriptors. Results are cached.

---

### Errors

**`prelude.Error`**
`create-error message, cause` — builds an `Error` with a `cause` chain embedded in the message. WSH JScript has no native error chaining; this gives you a readable cause trail in the message string itself.

**`prelude.error.Argument`**
`create-argument-error { arg: value }, message` — produces errors like:

```
Argument 'arg' with value <String> 'hello' must be a number.
```

**`prelude.error.Context`**
The crown jewel. `create-error-context` takes a qualified namespace string and returns a context object that wraps all errors thrown within a dependency with that namespace:

```livescript
{ arg-is-a, argerror } = create-error-context 'com.example.MyModule'
```

Any error thrown through `arg-is-a` or `argerror` gets stamped:

```
(Namespace: com.example.MyModule) Argument 'value' with value <String> 'a' must be <Number>.
  Caused by: Argument 'value' with value <String> 'a' must be Number as per type descriptor '<Number>'.
```

WSH JScript gives you no stack traces and no module system. The namespace context is your stack trace — you always know exactly which dependency threw and why.

The context also exposes typed argument validators for convenience: `StringArg`, `NumberArg`, `BooleanArg`, `ObjectArg`, `ArrayArg`, `FunctionArg`, and their `Maybe*` nullable variants.

---

## Dependency Graph

```
Type
TypeTag        → Type
TypeName       → TypeTag, Object
Value          → TypeTag, TypeName, Char, Circumfix, Function

String         → Type
Whitespace     → RegExp, Char, Type
Char           → Type
Circumfix      → Type
Case           → Char, RegExp, String
RegExp         → TypeTag, Type, String, Char, Circumfix, Array

Array          → TypeTag, Type
Object         → Type
Function       → Type, Whitespace, Array
Iteration      → Type

Error          → Type, String, Char

reflection.Argument    → Error, Value, Object, Array, Type
reflection.TypeDescriptor → error.Argument, Whitespace, Type, RegExp, Array, Char, String, Case
reflection.IsA         → reflection.TypeDescriptor, error.Argument, Object, TypeName, TypeTag, Type, Array, Function, Case, reflection.Argument

error.Argument → reflection.Argument, Error
error.Context  → error.Argument, reflection.IsA, Char, Circumfix
```
