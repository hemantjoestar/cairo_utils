if submodules: git submodule update --init --recursive


Utilities common to many project types.

- Sundry: frequently used utils i wish were in Corelib
- Array_utils: pack, reverse, move, copy
- Hashing: Sha256

- Testing
- TODO:
  - egcd needs more tests
  - also corelib has egcd. maybe a comparision
  - sha_256:use u128 since the boolean operations are running using libfuncs and using u64 includes to and from into jumps

- Notes to self:
  - array methods consume the array. i need this else forget i mutated the array
  - `trait` methodscan consume `self`. If `self` passed in without modifier ex. `mut`, `ref`
  - however if we need to modify we can use `mut` and still be consumed. this is to indicate that self is gonna be mutated andthen discarded
  - the trick is not in include the `mut` or `ref` keyowrd in the `trait` declaration, but you can use `mut` in the `impls`
  - same doesnt work with `ref`. ie using `ref` wont consume `self` and trait and impl have to match signatures
- IMP:
- using `@`  func signature has advantage only when using impls and traits. that is snapshot is autopassed
- else when using normal fucntions`@` doesnt provide anyconvenience. will have to explicity mention `@array` etc. better interface is `Span`
- use ref is you want to cotniue using, mut or nod modifier if it is to be consumed
