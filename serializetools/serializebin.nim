## Support for serialization of objects to and from binary

import streams, typeinfo, tables, array1d, endians, strutils, serialstring, array2d, sqarray2d

#const niledbDebug = true

# Useful for debugging
proc printBin(x:string): string =
  ## Print a binary string
  result = "0x"
  for e in items(x):
    result.add(toHex($e))

# forward decl
proc doStoreSetBinary(s: Stream, len: int32, a: Any)
  ## reads an XML representation `s` and transforms it to a set[T]

proc doStoreBinary[T](s: Stream, data: T) =
  # Compile-time telephone book. 
  when declared(niledbDebug): echo "enter doStoreBin: size= ", sizeof(data)

  when (T is char):
    s.write(data)

  elif (T is bool):
    if data:
      s.write(char(1))
    else:
      s.write(char(0))

  elif (T is SomeNumber):
    when declared(niledbDebug): echo "write number: size= ", sizeof(data)
    when cpuEndian == bigEndian:
      s.write(data)
    elif cpuEndian == littleEndian:
      var dd: T
      shallowCopy(dd, data)
      var d: T
      when sizeof(T) == 2:
        bigEndian16(d.addr, dd.addr)
      elif sizeof(T) == 4:
        bigEndian32(d.addr, dd.addr)
      elif sizeof(T) == 8:
        bigEndian64(d.addr, dd.addr)
      else:
        assert false
        raise newException(IOError, "doStoreBinary: error - unsupported data size")
      s.writeData(d.addr, sizeof(T))

  elif (T is string):
    when declared(niledbDebug): echo "write string: len= ", data.len
    let d = int32(data.len)
    doStoreBinary(s, d)
    if d > 0:
      var dd: T
      shallowCopy(dd, data)
      s.writeData(dd[0].addr, d)
    when declared(niledbDebug): echo "write string: ", printBin(data), "  len= ", d

  elif (T is cstring):
    # write a line-feed terminated string
    var dd: T
    shallowCopy(dd, data)
    s.writeData(dd[0].addr, data.len)
    var nn: array[1, char]
    nn[0] = '\x0a'
    s.writeData(nn[0].addr, 1)

  elif (T is SerialString):
    # write a line-feed terminated string
    var dd: string
    shallowCopy(dd, string(data))
    s.writeData(dd[0].addr, data.len)
    var nn: array[1, char]
    nn[0] = '\x0a'
    s.writeData(nn[0].addr, 1)

  elif (T is Array1dO):
    let d = int32(data.data.len)
    doStoreBinary(s, d)
    for v in data.data.items:
      doStoreBinary(s, v)

  elif (T is Array2d):
    let dl = int32(data.nrows)
    let dr = int32(data.ncols)
    doStoreBinary(s, dl)
    doStoreBinary(s, dr)
    for v in items(data):
      doStoreBinary(s, v)

  elif (T is SqArray2d):
    let dl = int32(data.nrows)
    doStoreBinary(s, dl)
    for v in items(data):
      doStoreBinary(s, v)

  elif (T is Table):
    doStoreBinary(s, int32(data.len))
    for k, v in data.pairs:
      doStoreBinary(s, k)
      doStoreBinary(s, v)

  elif (T is array|seq):
    when declared(niledbDebug): echo "write array|seq: len= ", data.len
    doStoreBinary(s, int32(data.len))
    for v in data.items:
      doStoreBinary(s, v)

  elif (T is set):
    var dd:T
    shallowCopy(dd, data)
    doStoreSetBinary(s, int32(data.card), toAny(dd))

  elif (T is tuple):
    for k, v in data.fieldPairs:
      doStoreBinary(s, v)

  elif (T is object):
    when declared(niledbDebug): echo "write object: size= ", sizeof(data)
    for k, v in data.fieldPairs:
      doStoreBinary(s, v)

  else:
    raise newException(IOError, "doStoreBinary: error - unsupported type of output: repr(data)= " & repr(data))

proc doStoreSetBinary(s: Stream, len: int32, a: Any) =
  ## reads an XML representation `s` and transforms it to a set[T]
  if a.baseTypeSize != 1:
    raise newException(IOError, "doStoreSetBinary: only support single byte sets: found size= " & $a.baseTypeSize)
  doStoreBinary(s, len)
  case a.kind
  of akSet:
    for e in elements(a):
      let x = cast[char](e)
      s.write(x)
  else:
    raise newException(IOError, "doStoreSetBinary: error in binary writer")

# Main serialization function
proc serializeBinary*[T](x: T): string =
  when declared(niledbDebug): echo "Enter serializeBinary: size= ", sizeof(x)
  var s = newStringStream()
  doStoreBinary(s, x)
  result = s.data


#--------------------------------------------------------------------------
# Deserialization support
#
proc doLoadNumber[T](s: var StringStream, data: var T) =
  ## reads an Binary representation `s` and transforms it to a ``T``
  # Compile-time telephone book. 
  when declared(niledbDebug): echo "Entering do size: size= ", sizeof(data), "  s= ", printBin(s.data)
  when cpuEndian == bigEndian:
    when declared(niledbDebug): echo "big: size= ", sizeof(T)
    s.readData(data.addr, sizeof(T))
  elif cpuEndian == littleEndian:
    var d:T
    when declared(niledbDebug): echo "little: size= ", sizeof(d)
    discard s.readData(d.addr, sizeof(T))
    when sizeof(T) == 2:
      swapEndian16(data.addr, d.addr)
    elif sizeof(T) == 4:
      swapEndian32(data.addr, d.addr)
    elif sizeof(T) == 8:
      swapEndian64(data.addr, d.addr)
    else:
      assert false
      raise newException(IOError, "doLoadSize: error - unsupported data size")
  when declared(niledbDebug): echo "number: data= ", data, "  size= ", sizeof(data)


# forward decl
proc doLoadBinary*[T](s: var StringStream, data: var T)
  ## reads an Binary representation `s` and transforms it to a ``T``

proc doLoadSetBinary(s: var StringStream, a: Any) =
  ## reads an XML representation `s` and transforms it to a set[T]
  when declared(niledbDebug): echo "Entering doLoadSet: baseTypeSize= ", a.baseTypeSize
  var len: int32
  doLoadNumber(s, len)
  if a.baseTypeSize != 1:
    raise newException(IOError, "doLoadSetBinary: only support single byte sets")
  case a.kind
  of akSet:
    for i in 0..len-1:
      let d = s.readChar()
      inclSetElement(a, int(d))
  else:
    raise newException(IOError, "storeAnyXML: error in xml writer - unsupported kind= " & $a.kind)
  when declared(niledbDebug): echo "doload Set:"

proc doLoadTableBinary[K,V](s: var StringStream, val: var Table[K,V]) =
  ## reads an XML representation `s` and transforms it to a Table[K,V]
  when declared(niledbDebug): echo "Entering doLoadTable: size= ", sizeof(val)
  val = initTable[K,V]()
  var d: int32
  doLoadNumber(s, d)
  for i in 0..d-1:
    var k:K
    doLoadBinary(s, k)
    var v:V
    doLoadBinary(s, v)
    val[k] = v
  when declared(niledbDebug): echo "doload Table: val= ", val, "  size= ", sizeof(val)

proc doLoadBinary*[T](s: var StringStream, data: var T) =
  ## reads an Binary representation `s` and transforms it to a ``T``
  # Compile-time telephone book. 
  when declared(niledbDebug): echo "Entering doLoad: size= ", sizeof(data), "  s= ", printBin(s.data)

  when (T is char):
    when declared(niledbDebug): echo "entering char"
    data = s.readChar()
    when declared(niledbDebug): echo "char: data= ", data, "  size= ", sizeof(data)

  elif (T is bool):
    when declared(niledbDebug): echo "entering bool"
    let dd = s.readChar()
    if dd == char(1):
      data = true
    else:
      data = false
    when declared(niledbDebug): echo "bool: data= ", data, "  size= ", sizeof(data)

  elif (T is SomeNumber):
    doLoadNumber(s, data)

  elif (T is string):
    when declared(niledbDebug): echo "entering string"
    var d: int32
    doLoadNumber(s, d)
    data = newString(d)
    if d > 0:
      discard s.readData(data[0].addr, d)
    when declared(niledbDebug): echo "string: data= ", data, "  len= ", d, "  size= ", sizeof(data)

  elif (T is cstring):
    when declared(niledbDebug): echo "entering cstring"
    var ddata = ""
    if not s.readLine(ddata):
      quit("doLoadBinary: some error parsing cstring")
    data = ddata
    when declared(niledbDebug): echo "cstring: data= ", data, "  size= ", sizeof(data)

  elif (T is SerialString):
    when declared(niledbDebug): echo "entering Serial"
    var ddata = ""
    if not s.readLine(ddata):
      quit("doLoadBinary: some error parsing cstring")
    data = SerialString(ddata)
    when declared(niledbDebug): echo "SerialString: data= ", data, "  size= ", sizeof(data)

  elif (T is Array1dO):
    when declared(niledbDebug): echo "entering array1do"
    type TT = type(data.data[0])
    var d: int32
    doLoadNumber(s, d)
    data.data = newSeq[TT](d)
    for v in data.data.mitems:
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "Array1dO: data= ", data, "  size= ", sizeof(data)

  elif (T is Array2d):
    when declared(niledbDebug): echo "entering array2d"
    type TT = type(data[0,0])
    var dl, dr: int32
    doLoadNumber(s, dl)
    doLoadNumber(s, dr)
    data = newArray2d[TT](dl,dr)
    for v in mitems(data):
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "Array2d: data= ", data, "  size= ", sizeof(data)

  elif (T is SqArray2d):
    when declared(niledbDebug): echo "entering sqarray2d"
    type TT = type(data[0,0])
    var dl: int32
    doLoadNumber(s, dl)
    data = newSqArray2d[TT](dl)
    for v in mitems(data):
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "SqArray2d: data= ", data, "  size= ", sizeof(data)

  elif (T is Table):
    when declared(niledbDebug): echo "entering table"
    doLoadTableBinary(s, data)
    when declared(niledbDebug): echo "Table: data= ", data, "  size= ", sizeof(data)

  elif (T is seq):
    when declared(niledbDebug): echo "entering seq"
    type TT = type(data[0])
    var d: int32 
    doLoadNumber(s, d)
    when declared(niledbDebug): echo "seq: d= ", d, "  size= ", sizeof(d), "  sz(TT)= ", sizeof(TT)
    data = newSeq[TT](d)
    for v in data.mitems:
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "seq: data= ", data, "  size= ", sizeof(data)

  elif (T is array):
    when declared(niledbDebug): echo "In array T"
    var d: int32
    doLoadNumber(s, d)
    #when declared(niledbDebug): echo "array: d= ", d, "  size= ", sizeof(d)
    #echo "array: d= ", d, "  len= ", sizeof(data.len)
    assert(d == data.len)
    for i in 0..data.len-1:
      doLoadBinary(s, data[i])
    #when declared(niledbDebug): echo "read array: size= ", sizeof(data)
    #echo "read array: size= ", sizeof(data)

  elif (T is set):
    when declared(niledbDebug): echo "entering set"
    doLoadSetBinary(s, toAny(data))
    when declared(niledbDebug): echo "set: data= ", data, "  size= ", sizeof(data)

  elif (T is tuple):
    when declared(niledbDebug): echo "entering tuple"
    for k, v in data.fieldPairs:
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "tuple: data= ", data, "  size= ", sizeof(data)

  elif (T is object):
    when declared(niledbDebug): echo "entering object"
    for k, v in data.fieldPairs:
      when declared(niledbDebug): echo "loop: obj- size= ", sizeof(v), "  k= ", k
      doLoadBinary(s, v)
    when declared(niledbDebug): echo "object: data= ", data, "  size= ", sizeof(data)

  else:
    raise newException(IOError, "deserializeBinary: error - unsupported type")


proc deserializeBinary*[T](s: string): T =
  ## reads an Binary representation in the string `s` and transforms it to a ``T``.
  when declared(niledbDebug): echo "Entering Binary: size= ", sizeof(T)
  var ss = newStringStream(s)
  doLoadBinary[T](ss, result)

