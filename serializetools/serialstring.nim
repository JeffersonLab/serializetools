## A string that can be serialized like a c-style string

import hashes

type
  SerialString* = distinct string

#proc SerialString*(x: string): SerialString = return SerialString(x)

proc `$`*(x: SerialString): string =
  return string(x)
  
proc len*(x: SerialString): int {.borrow.}
  
proc `==`*(x, y: SerialString): bool {.borrow.}

proc hash*(x: SerialString): Hash =
  ## Computes a Hash from `x`.
  return hash($x)
      
#proc `!=`(x, y: SerialString): bool {.borrow.}

#[
proc `[]`*(x: SerialString): int {.borrow.}
  
proc `[]`*[I: Ordinal](a: SerialString; i: I): SerialString {.borrow.}
proc `[]=`*[I: Ordinal;T,S](a: T; i: I; x: S) {.noSideEffect, magic: "ArrPut".}
proc `=`*[T](dest: var T; src: T) {.noSideEffect, magic: "Asgn".}
]#


#when isMainModule:
#  var foo: SerialString
#  foo = "here it is"
