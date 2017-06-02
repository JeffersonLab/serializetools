# Package

version       = "1.4.0"
author        = "Robert Edwards"
description   = "Support for serialization of objects"
license       = "MIT"

# Dependencies

requires "nim >= 0.17.0"

# Builds
skipDirs = @["tests"]

task test, "Runs the test suite":
  exec "nim c -r tests/test_xml"
  exec "nim c -r tests/test_binary"
