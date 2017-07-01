## A string that can be serialized like a c-style string

import hashes

type
  SerialString* = distinct string

proc `$`*(x: SerialString): string =
  ## A SerialString is still just a string
  return string(x)
  
proc len*(x: SerialString): int {.borrow.}
  
proc `==`*(x, y: SerialString): bool {.borrow.}

proc hash*(x: SerialString): Hash =
  ## Computes a Hash from `x`.
  return hash($x)
      
