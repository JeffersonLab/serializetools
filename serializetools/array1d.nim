## Support for 1D arrays (sequences) that are 1-based

import hashes

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

proc hash*[T](x: Array1dO[T]): Hash =
  result = x.data.hash

#----------------------------------------------------------------------------
when isMainModule:
  import tables

  # Define the array first
  var fred: Array1dO[int]
  fred.data = @[1, 7, -5]
  echo "fred = ", fred

  var sally: Array1dO[int]
  sally.data = @[3, 4, 5]
  echo "sally = ", sally

  var george: Array1dO[int]
  george.data = @[-3, -2, -1]
  echo "george = ", george

  # Now make a table out of it
  var foo = initTable[type(fred), string]()
  foo.add(fred,   "boo")
  foo.add(sally,  "foo")
  foo.add(george, "roo")

  echo "Table= ", foo

