import std/atomics

var a: Atomic[int]
store(a, 0, moRelaxed)