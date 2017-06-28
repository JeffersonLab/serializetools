## Support for serialization of objects to and from binary

import streams, typeinfo, tables, array1d, endians, strutils

proc doStoreSetBinary(s: Stream, len: int, a: Any) =
  ## reads an XML representation `s` and transforms it to a set[T]
  if a.baseTypeSize != 1:
    raise newException(IOError, "doStoreSetBinary: only support single byte sets: found size= " & $a.baseTypeSize)
  s.write(int32(len))
  case a.kind
  of akSet:
    for e in elements(a):
      let x = cast[char](e)
      s.write(x)
  else:
    raise newException(IOError, "doStoreSetBinary: error in binary writer")

proc doStoreBinary[T](s: Stream, data: T) =
  # Compile-time telephone book. 
  when (T is char):
    s.write(data)

  elif (T is bool):
    if data:
      s.write(char(1))
    else:
      s.write(char(0))

  elif (T is SomeNumber):
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
    let d = int32(data.len)
    s.write(d)
    var dd: T
    shallowCopy(dd, data)
    s.writeData(dd[0].addr, d)

  elif (T is cstring):
    # write a null-terminated string
    var dd: T
    shallowCopy(dd, data)
    s.writeData(dd[0].addr, data.len)
    var nn: array[1, char]
    nn[0] = '\x00'
    s.writeData(nn[0].addr, 1)

  elif (T is Array1dO):
    let d = int32(data.data.len)
    s.write(d)
    for v in data.data.items:
      doStoreBinary(s, v)

  elif (T is Table):
    s.write(int32(data.len))
    for k, v in data.pairs:
      doStoreBinary(s, k)
      doStoreBinary(s, v)

  elif (T is array|seq):
    s.write(int32(data.len))
    for v in data.items:
      doStoreBinary(s, v)

  elif (T is set):
    var dd:T
    shallowCopy(dd, data)
    doStoreSetBinary(s, data.card, toAny(dd))

  elif (T is tuple):
    for k, v in data.fieldPairs:
      doStoreBinary(s, v)

  elif (T is object):
    for k, v in data.fieldPairs:
      doStoreBinary(s, v)

  else:
    raise newException(IOError, "doStoreBinary: error - unsupported type of output: repr(data)= " & repr(data))

# Main serialization function
proc serializeBinary*[T](x: T): string =
  var s = newStringStream()
  doStoreBinary(s, x)
  result = s.data


#--------------------------------------------------------------------------
# Deserialization support
#

# forward decl
proc doLoadBinary*[T](s: Stream, data: var T)
  ## reads an Binary representation `s` and transforms it to a ``T``

proc doLoadSetBinary(s: Stream, a: Any) =
  ## reads an XML representation `s` and transforms it to a set[T]
  let len = s.readInt32()
  if a.baseTypeSize != 1:
    raise newException(IOError, "doLoadSetBinary: only support single byte sets")
  case a.kind
  of akSet:
    for i in 0..len-1:
      let d = s.readChar()
      inclSetElement(a, int(d))
  else:
    raise newException(IOError, "storeAnyXML: error in xml writer - unsupported kind= " & $a.kind)

proc doLoadTableBinary[K,V](s: Stream, val: var Table[K,V]) =
  ## reads an XML representation `s` and transforms it to a Table[K,V]
  val = initTable[K,V]()
  let d = s.readInt32()
  for i in 0..d-1:
    var k:K
    doLoadBinary(s, k)
    var v:V
    doLoadBinary(s, v)
    val.add(k,v)

proc doLoadBinary*[T](s: Stream, data: var T) =
  ## reads an Binary representation `s` and transforms it to a ``T``
  # Compile-time telephone book. 
  when (T is char):
    data = s.readChar()

  elif (T is bool):
    let dd = s.readChar()
    if dd == char(1):
      data = true
    else:
      data = false

  elif (T is SomeNumber):
    when cpuEndian == bigEndian:
      s.readData(data.addr, sizeof(T))
    elif cpuEndian == littleEndian:
      var d:T
      discard s.readData(d.addr, sizeof(T))
      when sizeof(T) == 2:
        swapEndian16(data.addr, d.addr)
      elif sizeof(T) == 4:
        swapEndian32(data.addr, d.addr)
      elif sizeof(T) == 8:
        swapEndian64(data.addr, d.addr)
      else:
        assert false
        raise newException(IOError, "doStoreBinary: error - unsupported data size")

  elif (T is string):
    let d = s.readInt32()
    data = newString(d)
    discard s.readData(data[0].addr, d)

  elif (T is cstring):
    var ddata = ""
    if not s.readLine(ddata):
      quit("doLoadBinary: some error parsing cstring")
    data = ddata

  elif (T is Array1dO):
    type TT = type(data.data[0])
    let d = s.readInt32()
    data.data = newSeq[TT](d)
    for v in data.data.mitems:
      doLoadBinary(s, v)

  elif (T is Table):
    doLoadTableBinary(s, data)

  elif (T is seq):
    type TT = type(data[0])
    let d = s.readInt32()
    data = newSeq[TT](d)
    for v in data.mitems:
      doLoadBinary(s, v)

  elif (T is array):
    let d = s.readInt32()
    assert(d == data.len)
    for i in 0..data.len-1:
      doLoadBinary(s, data[i])

  elif (T is set):
    doLoadSetBinary(s, toAny(data))

  elif (T is tuple):
    for k, v in data.fieldPairs:
      doLoadBinary(s, v)

  elif (T is object):
    for k, v in data.fieldPairs:
      doLoadBinary(s, v)

  else:
    raise newException(IOError, "deserializeBinary: error - unsupported type")

proc deserializeBinary*[T](s: string): T =
  ## reads an Binary representation in the string `s` and transforms it to a ``T``.
  let ss = newStringStream(s)
  doLoadBinary[T](ss, result)

