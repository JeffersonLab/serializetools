# Package
version       = "1.16.2"
author        = "Robert Edwards"
description   = "Support for serialization of objects"
license       = "MIT"
#srcDir        = "serializetools"
#installDirs   = @["src", "tests", "docs"]
skipDirs = @["tests"]

# Dependencies
requires "nim >= 1.0.0"

# Builds
task test, "Run the test suite":
  exec "nim c -r tests/test_xml"
  exec "nim c -r tests/test_binary"

task docgen, "Generate the documentation":
  exec "nim doc2 --out:docs/serializexml.html serializetools/serializexml.nim"
  exec "nim doc2 --out:docs/serializebin.html serializetools/serializebin.nim"

