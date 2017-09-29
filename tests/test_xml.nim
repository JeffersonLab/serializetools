## Test the support for serialization of objects to and from xml

import serializexml, tables, xmltree, array1d, serialstring
import unittest, xmlparser, streams   # used by unit tests

# Helper function to cut down on the redundancy
#[
template helper[T](x: T): untyped =
  let xml = serializeXML(x)
  echo "test bool xml= ", xml
  let xx = deserializeXML[T](xml)
  echo "deserializeXML(T)= ", xx
  require(x == xx)
]#

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


suite "Tests of XML serialization functions":

  test "Deserialize bool":
    var x: bool = true
    let xml = serializeXML(x)
    echo "test bool xml= ", xml
    let xx = deserializeXML[bool](xml)
    echo "deserializeXML(bool)= ", xx
    require(x == xx)

  test "Deserialize int":
    var x: int = 17
    let xml = serializeXML(x)
    echo "test int xml= ", xml
    let xx = deserializeXML[int](xml)
    echo "deserializeXML(int)= ", xx
    require(x == xx)

  test "Deserialize string":
    var x = "foo/fred"
    let xml = serializeXML(x)
    echo "test string xml= ", xml
    let noescape_string = xmlToStr(xml)
    echo "corresponding conversion to string without escapes= ", noescape_string
    let noescape_stream = newStringStream(noescape_string)
    let parsed_xml = parseXml(noescape_stream)
    let xx = deserializeXML[string](parsed_xml)
    echo "deserializeXML(string)= ", xx
    require(x == xx)

  test "Deserialize SerialString":
    var x = SerialString("my fred")
    let xml = serializeXML(x)
    echo "test string xml= ", xml
    let xx = deserializeXML[SerialString](xml)
    echo "deserializeXML(SerialString)= ", xx
    require(x == xx)

  test "Deserialize empty string":
    var x = ""
    let xml = serializeXML(x)
    echo "test string xml= ", xml
    let xx = deserializeXML[string](xml)
    echo "deserializeXML(string)= ", xx
    require(x == xx)

  test "Deserialize uninitialized string":
    var x:string
    let xml = serializeXML(x)
    echo "test string xml= ", xml
    let xx = deserializeXML[string](xml)
    echo "deserializeXML(string)= ", xx
    require(x == xx)

  test "Deserialize int32":
    var x: int32 = 17i32
    let xml = serializeXML(x)
    echo "test int32 xml= ", xml
    let xx = deserializeXML[int](xml)
    echo "deserializeXML(int32)= ", xx
    require(x == xx)

  test "Deserialize float":
    var x: float = 17.1
    let xml = serializeXML(x)
    echo "test float xml= ", xml
    let xx = deserializeXML[float](xml)
    echo "deserializeXML(float)= ", xx
    require(x == xx)

  test "Deserialize float64":
    var x: float64 = 1.1
    let xml = serializeXML(x)
    echo "test float64 xml= ", xml
    let xx = deserializeXML[float64](xml)
    echo "deserializeXML(float64)= ", xx
    require(x == xx)

  test "Deserialize int":
    var x: int = 17
    let xml = serializeXML(x)
    echo "test int xml= ", xml
    let xx = deserializeXML[int](xml)
    echo "deserializeXML(int)= ", xx
    require(x == xx)

  test "Deserialize array[int]":
    type T = array[0..4, int]
    var x: T = [5, 7, 9, 11, 13]
    let xml = serializeXML(x)
    echo "test array[int] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(array[int])= ", @xx
    require(x == xx)

  test "Deserialize seq[string]":
    type T = seq[string]
    var x: T = @["ff", "boo", "nu"]
    let xml = serializeXML(x)
    echo "test seq[string] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(seq[string])= ", xx
    require(x == xx)

  test "Deserialize seq[int]":
    type T = seq[int]
    var x: T = @[5, 7, 9, 11, 13]
    let xml = serializeXML(x)
    echo "test seq[int] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(seq[int])= ", xx
    require(x == xx)

  test "Deserialize Array1dO[int]":
    type T = Array1dO[int]
    var x: T
    x.data = @[5, 7, 9, 11, 13]
    let xml = serializeXML(x)
    echo "test Array1dO[int] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(Array1dO[int])= ", xx
    require(x == xx)

  test "Deserialize tuple[]":
    type T = tuple[mama:string, papa:int, h:string]
    var x:T = (mama: "fred", papa: 17, h: "boo")
    let xml = serializeXML(x)
    echo "test tuple[string,int] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(Tuple[string,int])= ", xx
    require(x == xx)

  test "Deserialize Table[string,int]":
    type T = Table[string, int]
    var x:T = {"fred": 1, "george": 17}.toTable
#    x["boo"] = -5
#    x["foo"] = -8
    let xml = serializeXML(x)
    echo "test Table[string,int] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(Table[string,int])= ", xx
    require(x == xx)

  test "Deserialize Object":
    type T = Fred
    var x: T = fred
    let xml = serializeXML(x)
    echo "test object xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(object)= ", xx
    require(x == xx)

  test "Deserialize Map[Map]":
    type 
      TT = Table[string, int]
      T  = Table[string, TT]

    var y:TT  = {"fred": 1, "george": 17}.toTable
    var x:T   = initTable[string,TT]()
    x["oops"]  = y
    x["daisy"] = y

    let xml = serializeXML(x)
    echo "test map[map] xml= ", xml
    let xx = deserializeXML[T](xml)
    echo "deserializeXML(map[map])= ", xx
    require(x == xx)

  test "Deserialize XmlNode":
    type T = XmlNode
    var xx = @[5, 7, 9, 11, 13]
    let x = serializeXML(xx)
    echo "test XmlNode= ", x
    let xyz = deserializeXML[T](x)
    echo "deserializeXML(XmlNode)= ", xyz
    require(x == xyz)



