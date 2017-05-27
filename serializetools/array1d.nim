## Support for 1D arrays (sequences) that are 1-based

type
  Array1dO*[T] = object
    data*: seq[T]

proc `$`*[T](a: Array1dO[T]): string =
  result = $a.data

proc low*[T](a: Array1dO[T]): int = 
  result = 1

proc high*[T](a: Array1dO[T]): int = 
  result = a.data+1

proc `[]`*[T](a: Array1dO[T], i:Positive): T =
    result = a.data[i-1]

proc `[]=`*[T](a: var Array1dO[T], i:Positive): T =
    result = a.data[i-1]

