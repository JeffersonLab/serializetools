## Support for 2D arrays (sequences) that are 0-based

import hashes

type
  SqArray2d*[T] = object
    nrows*: int
    data*:  seq[T]

proc `$`*[T](a: SqArray2d[T]): string =
  result = $a.data

proc nrows*[T](a: SqArray2d[T]): int =
  ## The row dimension
  return nrows

proc `[]`*[T](a: SqArray2d[T], i,j: int): T =
  ## Indexing
  a.data[i*a.nrows + j]

proc `[]=`*[T](a: var SqArray2d[T], i,j: int, v: T) =
  ## Assignment
  a.data[i*a.nrows + j] = v

proc hash*[T](x: SqArray2d[T]): Hash =
  result = x.data.hash

proc newSqArray2d*[T](nrow: int): SqArray2d[T] =
  result.nrows = nrow
  result.data  = newSeq[T](nrow*nrow)

iterator items*[T](a: SqArray2d[T]): T {.inline.} =
  ## Iterator
  var i = 0
  while i < len(a.data):
    yield a.data[i]
    inc(i)

iterator mitems*[T](a: var SqArray2d[T]): var T {.inline.} =
  ## Modifiable iterator
  var i = 0
  while i < len(a.data):
    yield a.data[i]
    inc(i)



#----------------------------------------------------------------------------
when isMainModule:
  # Define the array first
  var fred = newSqArray2d[float](2,2)
  fred[0,0] = 1.0
  fred[0,1] = 2.0
  fred[1,0] = 3.0
  fred[1,1] = 4.0
  echo "fred = ", fred
  echo "fred[1,0]= ", fred[1,0]

  var sally = newSqArray2d[float](2,2)
  sally[0,0] = 1.0
  sally[0,1] = 2.0
  sally[1,0] = 3.0
  sally[1,1] = 4.0
  echo "sally = ", sally

  # Check iterator
  for v in items(fred):
    echo "v= ", v
