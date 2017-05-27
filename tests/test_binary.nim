## Test the support for serialization of objects to and from xml

import serializebin, tables, array1d, strutils
import unittest

type
  Fred = object
    b: bool
    c: char
    f: float64
    h: int32
    j: string
    k: seq[int32]
    m: set[char]
    n: Table[string,int]

var fred = Fred(b: true, h: 17, j: "hello world", k: @[1i32,2i32,3i32], f: 1.1, c: 'M', m: {'a'..'g'})
fred.n ={"yummy": 10, "tasty": 20}.toTable

proc printBin(x:string): string =
  result = "0x"
  for e in items(x):
    result.add(toHex(e))

suite "Tests of Binary serialization functions":
  test "Deserialize bool":
    var x: bool = true
    let bin = serializeBinary(x)
    echo "test bool bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(bool)= ", xx
    require(x == xx)

  test "Deserialize int":
    var x: int = 17
    let bin = serializeBinary(x)
    echo "test int bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(int)= ", xx
    require(x == xx)

  test "Deserialize string":
    var x = "my fred"
    let bin = serializeBinary(x)
    echo "test string bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(string)= ", xx
    require(x == xx)

  test "Deserialize int32":
    var x: int32 = 17i32
    let bin = serializeBinary(x)
    echo "test int32 bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(int32)= ", xx
    require(x == xx)

  test "Deserialize float":
    var x: float = 17.1
    let bin = serializeBinary(x)
    echo "test float bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(float)= ", xx
    require(x == xx)

  test "Deserialize float64":
    var x: float64 = 1.1
    let bin = serializeBinary(x)
    echo "test float64 bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(float64)= ", xx
    require(x == xx)

  test "Deserialize int":
    var x: int = 17
    let bin = serializeBinary(x)
    echo "test int bin= ", printBin(bin)
    let xx = deserializeBinary[type(x)](bin)
    echo "deserializeBinary(int)= ", xx
    require(x == xx)

  test "Deserialize array[int]":
    type T = array[0..4, int]
    var x: T = [5, 7, 9, 11, 13]
    let bin = serializeBinary(x)
    echo "test array[int] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(array[int])= ", @xx
    require(x == xx)

  test "Deserialize seq[string]":
    type T = seq[string]
    var x: T = @["ff", "boo", "nu"]
    let bin = serializeBinary(x)
    echo "test seq[string] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(seq[string])= ", xx
    require(x == xx)

  test "Deserialize seq[int]":
    type T = seq[int]
    var x: T = @[5, 7, 9, 11, 13]
    let bin = serializeBinary(x)
    echo "test seq[int] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(seq[int])= ", xx
    require(x == xx)

  test "Deserialize Array1dO[int]":
    type T = Array1dO[int]
    var x: T
    x.data = @[5, 7, 9, 11, 13]
    let bin = serializeBinary(x)
    echo "test Array1dO[int] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(Array1dO[int])= ", xx
    require(x == xx)

  test "Deserialize set[char]":
    type T = set[char]
    let x: T = {'a'..'g'}
    let bin = serializeBinary(x)
    writeLine(stdout, "test set[char] bin= " & bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(set[char])= ", xx
    require(x == xx)

  test "Deserialize tuple[]":
    type T = tuple[mama:string, papa:int, h:string]
    var x:T = (mama: "fred", papa: 17, h: "boo")
    let bin = serializeBinary(x)
    echo "test tuple[string,int] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(Tuple[string,int])= ", xx
    require(x == xx)

  test "Deserialize Table[string,int]":
    type T = Table[string, int]
    var x:T = {"fred": 1, "george": 17}.toTable
#    x["boo"] = -5
#    x["foo"] = -8
    let bin = serializeBinary(x)
    echo "test Table[string,int] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(Table[string,int])= ", xx
    require(x == xx)

  test "Deserialize Object":
    type T = Fred
    var x: T = fred
    let bin = serializeBinary(x)
    echo "test object bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(object)= ", xx
    require(x == xx)

  test "Deserialize Map[Map]":
    type 
      TT = Table[string, int]
      T  = Table[string, TT]

    var y:TT  = {"fred": 1, "george": 17}.toTable
    var x:T   = initTable[string,TT]()
    x["oops"]  = y
    x["daisy"] = y

    let bin = serializeBinary(x)
    echo "test map[map] bin= ", printBin(bin)
    let xx = deserializeBinary[T](bin)
    echo "deserializeBinary(map[map])= ", xx
    require(x == xx)

