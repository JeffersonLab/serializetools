## Support for CRC32

import strutils

type CRC32* = uint32
const initCRC32:uint32 = (0xffff shl 16) or 0xffff
# const initCRC32:uint32 = CRC32(-1)
# const initCRC32 = CRC32(-1)

proc createCRCTable(): array[256, CRC32] =
  for i in 0..255:
    var rem = CRC32(i)
    for j in 0..7:
      if (rem and 1) > 0: rem = (rem shr 1) xor CRC32(0xedb88320)
      else: rem = rem shr 1
    result[i] = rem
#  echo "Here is the table: ", result.repr

# Table created at runtime
## var crc32table = createCRCTable()

# Table created at compile time
const crc32table = createCRCTable()

# Check the representation
#echo crc32table.repr

# The application function
proc crc32*(s:string): CRC32 =
  ## Compute the CRC32 on the string `s`
  result = initCRC32
  for c in s:
    result = (result shr 8) xor crc32table[(result and 0xff) xor ord(c)]
  result = not result

# String conversion proc $, automatically called by echo
proc `$`(c: CRC32): string = int64(c).toHex(8)

#--------------------------------------------------------------------------
# Some basic tests
when isMainModule:
  echo "initCRC32 = ", $initCRC32
  let foo = crc32("The quick brown fox jumps over the lazy dog")
  assert(foo == 0x414FA339)
