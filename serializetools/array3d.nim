## Support for 3D arrays (sequences) that are 0-based

import hashes

type
  Array3d*[T] = object
    n3*: int
    n2*: int
    n1*: int
    data*:  seq[T]

proc `$`*[T](a: Array3d[T]): string =
  result = $a.data

proc size1*[T](a: Array3d[T]): int =
  ## The size1 dimension
  return a.n1

proc size2*[T](a: Array3d[T]): int = 
  ## The size2 dimension
  return a.n2

proc size3*[T](a: Array3d[T]): int = 
  ## The size3 dimension
  return a.n3

proc `[]`*[T](a: Array3d[T], k,j,i: int): T =
  ## Indexing
  a.data[i+a.n1*(j+a.n2*(k))]

proc `[]=`*[T](a: var Array3d[T], k,j,i: int, v: T) =
  ## Assignment
  a.data[i+a.n1*(j+a.n2*(k))] = v

proc hash*[T](x: Array3d[T]): Hash =
  result = x.data.hash

proc newArray3d*[T](n3,n2,n1: int): Array3d[T] =
  result.n1 = n1
  result.n2 = n2
  result.n3 = n3
  result.data  = newSeq[T](n1*n2*n3)

iterator items*[T](a: Array3d[T]): T {.inline.} =
  ## Iterator
  var i = 0
  while i < len(a.data):
    yield a.data[i]
    inc(i)

iterator mitems*[T](a: var Array3d[T]): var T {.inline.} =
  ## Modifiable iterator
  var i = 0
  while i < len(a.data):
    yield a.data[i]
    inc(i)



#----------------------------------------------------------------------------
when isMainModule:
  # Define the array first
  var fred = newArray3d[float](2,2,2)
  for i in 0..1:
    for j in 0..1:
      for k in 0..1:
        fred[k,j,i] = float(i+2*(j+2*(k)))
  echo "fred = ", fred
  echo "fred[1,0,1]= ", fred[1,0,1]

  # Check iterator
  for v in items(fred):
    echo "v= ", v
