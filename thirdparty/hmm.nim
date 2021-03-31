import math

{.compile: "./hmm.c".}

when defined(i386) or defined(amd64):
  # SIMD throughput and latency:
  #   - https://software.intel.com/sites/landingpage/IntrinsicsGuide/
  #   - https://www.agner.org/optimize/instruction_tables.pdf

  # Reminder: x86 is little-endian, order is [low part, high part]
  # Documentation at https://software.intel.com/sites/landingpage/IntrinsicsGuide/

  when defined(vcc):
    {.pragma: x86_type, byCopy, header:"<intrin.h>".}
    {.pragma: x86, noDecl, header:"<intrin.h>".}
  else:
    {.pragma: x86_type, byCopy, header:"<x86intrin.h>".}
    {.pragma: x86, noDecl, header:"<x86intrin.h>".}
  type
    m128* {.importc: "__m128", x86_type.} = object
      raw: array[4, float32]
    m128d* {.importc: "__m128d", x86_type.} = object
      raw: array[2, float64]
    m128i* {.importc: "__m128i", x86_type.} = object
      raw: array[16, byte]
    m256* {.importc: "__m256", x86_type.} = object
      raw: array[8, float32]
    m256d* {.importc: "__m256d", x86_type.} = object
      raw: array[4, float64]
    m256i* {.importc: "__m256i", x86_type.} = object
      raw: array[32, byte]
    m512* {.importc: "__m512", x86_type.} = object
      raw: array[16, float32]
    m512d* {.importc: "__m512d", x86_type.} = object
      raw: array[8, float64]
    m512i* {.importc: "__m512i", x86_type.} = object
      raw: array[64, byte]
    mmask16* {.importc: "__mmask16", x86_type.} = distinct uint16
    mmask64* {.importc: "__mmask64", x86_type.} = distinct uint64

proc mm_set_ss(w: float32): m128 {.importc: "_mm_set_ss".}
proc mm_sqrt_ss(w: m128): m128 {.importc: "_mm_sqrt_ss".}
proc mm_rsqrt_ss(w: m128): m128 {.importc: "_mm_rsqrt_ss".}
proc mm_cvtss_f32(w: m128): float32 {.importc: "_mm_cvtss_f32".}
proc mm_setr_ps(a, b, c, d: float32): m128 {.importc: "_mm_setr_ps".}
proc mm_set_ps1(a: float32): m128 {.importc: "_mm_set_ps1".}
proc mm_store_ss(p: ptr float32; a: m128) {.importc: "_mm_store_ss".}
proc mm_add_ps(a, b: m128): m128 {.importc: "_mm_add_ps".}
proc mm_sub_ps(a, b: m128): m128 {.importc: "_mm_sub_ps".}
proc mm_mul_ps(a, b: m128): m128 {.importc: "_mm_mul_ps".}
proc mm_div_ps(a, b: m128): m128 {.importc: "_mm_div_ps".}
proc mm_shuffle_ps(a, b: m128; c: int32): m128 {.importc: "_mm_shuffle_ps".}
proc mm_xor_ps(a, b: m128): m128 {.importc: "_mm_xor_ps".}


type
  INNER_C_STRUCT_handmademath_pp_5* {.bycopy.} = object
    X*: cfloat
    Y*: cfloat

  INNER_C_STRUCT_handmademath_pp_10* {.bycopy.} = object
    U*: cfloat
    V*: cfloat

  INNER_C_STRUCT_handmademath_pp_15* {.bycopy.} = object
    l*: cfloat
    r*: cfloat

  INNER_C_STRUCT_handmademath_pp_20* {.bycopy.} = object
    Width*: cfloat
    Height*: cfloat

  INNER_C_STRUCT_handmademath_pp_31* {.bycopy.} = object
    X*: cfloat
    Y*: cfloat
    Z*: cfloat

  INNER_C_STRUCT_handmademath_pp_36* {.bycopy.} = object
    U*: cfloat
    V*: cfloat
    W*: cfloat

  INNER_C_STRUCT_handmademath_pp_41* {.bycopy.} = object
    R*: cfloat
    G*: cfloat
    B*: cfloat

  INNER_C_STRUCT_handmademath_pp_46* {.bycopy.} = object
    XY*: hmm_vec2
    Ignored0*: cfloat

  INNER_C_STRUCT_handmademath_pp_52* {.bycopy.} = object
    Ignored1*: cfloat
    YZ*: hmm_vec2

  INNER_C_STRUCT_handmademath_pp_58* {.bycopy.} = object
    UV*: hmm_vec2
    Ignored2*: cfloat

  INNER_C_STRUCT_handmademath_pp_64* {.bycopy.} = object
    Ignored3*: cfloat
    VW*: hmm_vec2

  INNER_C_STRUCT_handmademath_pp_81* {.bycopy.} = object
    X*: cfloat
    Y*: cfloat
    Z*: cfloat

  INNER_C_UNION_handmademath_pp_78* {.bycopy, union.} = object
    XYZ*: hmm_vec3
    ano_handmademath_pp_82*: INNER_C_STRUCT_handmademath_pp_81

  INNER_C_STRUCT_handmademath_pp_76* {.bycopy.} = object
    ano_handmademath_pp_83*: INNER_C_UNION_handmademath_pp_78
    W*: cfloat

  INNER_C_STRUCT_handmademath_pp_94* {.bycopy.} = object
    R*: cfloat
    G*: cfloat
    B*: cfloat

  INNER_C_UNION_handmademath_pp_91* {.bycopy, union.} = object
    RGB*: hmm_vec3
    ano_handmademath_pp_95*: INNER_C_STRUCT_handmademath_pp_94

  INNER_C_STRUCT_handmademath_pp_89* {.bycopy.} = object
    ano_handmademath_pp_96*: INNER_C_UNION_handmademath_pp_91
    A*: cfloat

  INNER_C_STRUCT_handmademath_pp_103* {.bycopy.} = object
    XY*: hmm_vec2
    Ignored0*: cfloat
    Ignored1*: cfloat

  INNER_C_STRUCT_handmademath_pp_110* {.bycopy.} = object
    Ignored2*: cfloat
    YZ*: hmm_vec2
    Ignored3*: cfloat

  INNER_C_STRUCT_handmademath_pp_117* {.bycopy.} = object
    Ignored4*: cfloat
    Ignored5*: cfloat
    ZW*: hmm_vec2

  INNER_C_STRUCT_handmademath_pp_147* {.bycopy.} = object
    X*: cfloat
    Y*: cfloat
    Z*: cfloat

  INNER_C_UNION_handmademath_pp_144* {.bycopy, union.} = object
    XYZ*: hmm_vec3
    ano_handmademath_pp_148*: INNER_C_STRUCT_handmademath_pp_147

  INNER_C_STRUCT_handmademath_pp_142* {.bycopy.} = object
    ano_handmademath_pp_149*: INNER_C_UNION_handmademath_pp_144
    W*: cfloat

  hmm_vec2* {.bycopy, union.} = object
    ano_handmademath_pp_6*: INNER_C_STRUCT_handmademath_pp_5
    ano_handmademath_pp_11*: INNER_C_STRUCT_handmademath_pp_10
    ano_handmademath_pp_16*: INNER_C_STRUCT_handmademath_pp_15
    ano_handmademath_pp_21*: INNER_C_STRUCT_handmademath_pp_20
    Elements*: array[2, cfloat]

  hmm_vec3* {.bycopy, union.} = object
    ano_handmademath_pp_32*: INNER_C_STRUCT_handmademath_pp_31
    ano_handmademath_pp_37*: INNER_C_STRUCT_handmademath_pp_36
    ano_handmademath_pp_42*: INNER_C_STRUCT_handmademath_pp_41
    ano_handmademath_pp_48*: INNER_C_STRUCT_handmademath_pp_46
    ano_handmademath_pp_54*: INNER_C_STRUCT_handmademath_pp_52
    ano_handmademath_pp_60*: INNER_C_STRUCT_handmademath_pp_58
    ano_handmademath_pp_66*: INNER_C_STRUCT_handmademath_pp_64
    Elements*: array[3, cfloat]

  hmm_vec4* {.bycopy, union.} = object
    ano_handmademath_pp_86*: INNER_C_STRUCT_handmademath_pp_76
    ano_handmademath_pp_99*: INNER_C_STRUCT_handmademath_pp_89
    ano_handmademath_pp_106*: INNER_C_STRUCT_handmademath_pp_103
    ano_handmademath_pp_113*: INNER_C_STRUCT_handmademath_pp_110
    ano_handmademath_pp_120*: INNER_C_STRUCT_handmademath_pp_117
    Elements*: array[4, cfloat]
    InternalElementsSSE*: m128

  hmm_mat4* {.bycopy, union.} = object
    Elements*: array[4, array[4, cfloat]]
    Columns*: array[4, m128]
    Rows*: array[4, m128]

  hmm_quaternion* {.bycopy, union.} = object
    ano_handmademath_pp_152*: INNER_C_STRUCT_handmademath_pp_142
    Elements*: array[4, cfloat]
    InternalElementsSSE*: m128

  hmm_bool* = cint
  hmm_v2* = hmm_vec2
  hmm_v3* = hmm_vec3
  hmm_v4* = hmm_vec4
  hmm_m4* = hmm_mat4

# hmm_vec2
template X(a: hmm_vec2): float32 =
  a.ano_handmademath_pp_6.X

template `X=`(a: var hmm_vec2; b: float32) =
  a.ano_handmademath_pp_6.X = b

template Y(a: hmm_vec2): float32 =
  a.ano_handmademath_pp_6.Y

template `Y=`(a: var hmm_vec2; b: float32) =
  a.ano_handmademath_pp_6.Y = b

# hmm_vec3

template X(a: hmm_vec3): float32 =
  a.ano_handmademath_pp_32.X

template `X=`(a: var hmm_vec3; b: float32) =
  a.ano_handmademath_pp_32.X = b

template Y(a: hmm_vec3): float32 =
  a.ano_handmademath_pp_32.Y

template `Y=`(a: var hmm_vec3; b: float32) =
  a.ano_handmademath_pp_32.Y = b

template Z(a: hmm_vec3): float32 =
  a.ano_handmademath_pp_32.Z

template `Z=`(a: var hmm_vec3; b: float32) =
  a.ano_handmademath_pp_32.Z = b

# hmm_vec4

template X(a: hmm_vec4): float32 =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.X

template `X=`(a: var hmm_vec4; b: float32) =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.X = b

template Y(a: hmm_vec4): float32 =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.Y

template `Y=`(a: var hmm_vec4; b: float32) =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.Y = b

template Z(a: hmm_vec4): float32 =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.Z

template `Z=`(a: var hmm_vec4; b: float32) =
  a.ano_handmademath_pp_86.ano_handmademath_pp_83.ano_handmademath_pp_82.Z = b

template W(a: hmm_vec4): float32 =
  a.ano_handmademath_pp_86.W

template `W=`(a: var hmm_vec4; b: float32) =
  a.ano_handmademath_pp_86.W = b

proc HMM_SinF*(Radians: cfloat): cfloat {.inline.} =
  var res: cfloat = sin(Radians)
  return res

proc HMM_CosF*(Radians: cfloat): cfloat {.inline.} =
  var res: cfloat = cos(Radians)
  return res

proc HMM_TanF*(Radians: cfloat): cfloat {.inline.} =
  var res: cfloat = tan(Radians)
  return res

proc HMM_ACosF*(Radians: cfloat): cfloat {.inline.} =
  var res: cfloat = arccos(Radians)
  return res

proc HMM_ATanF*(Radians: cfloat): cfloat {.inline.} =
  var res: cfloat = arctan(Radians)
  return res

proc HMM_ATan2F*(l: cfloat; r: cfloat): cfloat {.inline.} =
  var res: cfloat = arctan2(l, r)
  return res

proc HMM_ExpF*(f: cfloat): cfloat {.inline.} =
  var res: cfloat = exp(f)
  return res

proc HMM_LogF*(f: cfloat): cfloat {.inline.} =
  var res: cfloat = ln(f)
  return res

proc HMM_SquareRootF*(f: cfloat): cfloat {.inline.} =
  var res: cfloat
  var i: m128 = mm_set_ss(f)
  var o: m128 = mm_sqrt_ss(i)
  res = mm_cvtss_f32(o)
  return res

proc HMM_RSquareRootF*(f: cfloat): cfloat {.inline.} =
  var res: cfloat
  var i: m128 = mm_set_ss(f)
  var o: m128 = mm_rsqrt_ss(i)
  res = mm_cvtss_f32(o)
  return res

proc HMM_Power*(Base: cfloat; Exponent: cint): cfloat {.importc: "HMM_Power".}
proc HMM_PowerF*(Base: cfloat; Exponent: cfloat): cfloat {.inline.} =
  var res: cfloat = exp(Exponent * ln(Base))
  return res

proc HMM_ToRadians*(Degrees: cfloat): cfloat {.inline.} =
  var res: cfloat = Degrees * (3.14159265359 / 180.0)
  return res

proc HMM_Lerp*(A: cfloat; Time: cfloat; B: cfloat): cfloat {.inline.} =
  var res: cfloat = (1.0 - Time) * A + Time * B
  return res

proc HMM_Clamp*(Min: cfloat; Value: cfloat; Max: cfloat): cfloat {.inline.} =
  var res: cfloat = Value
  if res < Min:
    res = Min
  if res > Max:
    res = Max
  return res

proc HMM_Vec2*(X: cfloat; Y: cfloat): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = X
  res.ano_handmademath_pp_6.Y = Y
  return res

proc HMM_Vec2i*(X: cint; Y: cint): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = cast[cfloat](X)
  res.ano_handmademath_pp_6.Y = cast[cfloat](Y)
  return res

proc HMM_Vec3*(X: cfloat; Y: cfloat; Z: cfloat): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.ano_handmademath_pp_32.X = X
  res.ano_handmademath_pp_32.Y = Y
  res.ano_handmademath_pp_32.Z = Z
  return res

proc HMM_Vec3i*(X: cint; Y: cint; Z: cint): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.ano_handmademath_pp_32.X = cast[cfloat](X)
  res.ano_handmademath_pp_32.Y = cast[cfloat](Y)
  res.ano_handmademath_pp_32.Z = cast[cfloat](Z)
  return res

proc HMM_Vec4*(X: cfloat; Y: cfloat; Z: cfloat; W: cfloat): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_setr_ps(X, Y, Z, W)
  return res

proc HMM_Vec4i*(X: cint; Y: cint; Z: cint; W: cint): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_setr_ps(cast[cfloat](X), cast[cfloat](Y),
      cast[cfloat](Z), cast[cfloat](W))
  return res

proc HMM_Vec4v*(v: hmm_vec3; W: cfloat): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_setr_ps(v.ano_handmademath_pp_32.X, v.ano_handmademath_pp_32.Y, v.ano_handmademath_pp_32.Z, W)
  return res

proc HMM_AddVec2*(l: hmm_vec2; r: hmm_vec2): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = l.ano_handmademath_pp_6.X + r.ano_handmademath_pp_6.X
  res.ano_handmademath_pp_6.Y = l.ano_handmademath_pp_6.Y + r.ano_handmademath_pp_6.Y
  return res

proc HMM_AddVec3*(l: hmm_vec3; r: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.ano_handmademath_pp_32.X = l.ano_handmademath_pp_32.X + r.ano_handmademath_pp_32.X
  res.ano_handmademath_pp_32.Y = l.ano_handmademath_pp_32.Y + r.ano_handmademath_pp_32.Y
  res.ano_handmademath_pp_32.Z = l.ano_handmademath_pp_32.Z + r.ano_handmademath_pp_32.Z
  return res

proc HMM_AddVec4*(l: hmm_vec4; r: hmm_vec4): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_add_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_SubtractVec2*(l: hmm_vec2; r: hmm_vec2): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = l.ano_handmademath_pp_6.X - r.ano_handmademath_pp_6.X
  res.ano_handmademath_pp_6.Y = l.ano_handmademath_pp_6.Y - r.ano_handmademath_pp_6.Y
  return res

proc HMM_SubtractVec3*(l: hmm_vec3; r: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.ano_handmademath_pp_32.X = l.ano_handmademath_pp_32.X - r.ano_handmademath_pp_32.X
  res.ano_handmademath_pp_32.Y = l.ano_handmademath_pp_32.Y - r.ano_handmademath_pp_32.Y
  res.ano_handmademath_pp_32.Z = l.ano_handmademath_pp_32.Z - r.ano_handmademath_pp_32.Z
  return res

proc HMM_SubtractVec4*(l: hmm_vec4; r: hmm_vec4): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_sub_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_MultiplyVec2*(l: hmm_vec2; r: hmm_vec2): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = l.ano_handmademath_pp_6.X * r.ano_handmademath_pp_6.X
  res.ano_handmademath_pp_6.Y = l.ano_handmademath_pp_6.Y * r.ano_handmademath_pp_6.Y
  return res

proc HMM_MultiplyVec2f*(l: hmm_vec2; r: cfloat): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.ano_handmademath_pp_6.X = l.ano_handmademath_pp_6.X * r
  res.ano_handmademath_pp_6.Y = l.ano_handmademath_pp_6.Y * r
  return res

proc HMM_MultiplyVec3*(l: hmm_vec3; r: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.X = l.X * r.X
  res.Y = l.Y * r.Y
  res.Z = l.Z * r.Z
  return res

proc HMM_MultiplyVec3f*(l: hmm_vec3; r: cfloat): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.X = l.X * r
  res.Y = l.Y * r
  res.Z = l.Z * r
  return res

proc HMM_MultiplyVec4*(l: hmm_vec4; r: hmm_vec4): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_mul_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_MultiplyVec4f*(l: hmm_vec4; r: cfloat): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  var Scalar: m128 = mm_set_ps1(r)
  res.InternalElementsSSE = mm_mul_ps(l.InternalElementsSSE, Scalar)
  return res

proc HMM_DivideVec2*(l: hmm_vec2; r: hmm_vec2): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.X = l.X / r.X
  res.Y = l.Y / r.Y
  return res

proc HMM_DivideVec2f*(l: hmm_vec2; r: cfloat): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  res.X = l.X / r
  res.Y = l.Y / r
  return res

proc HMM_DivideVec3*(l: hmm_vec3; r: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.X = l.X / r.X
  res.Y = l.Y / r.Y
  res.Z = l.Z / r.Z
  return res

proc HMM_DivideVec3f*(l: hmm_vec3; r: cfloat): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.X = l.X / r
  res.Y = l.Y / r
  res.Z = l.Z / r
  return res

proc HMM_DivideVec4*(l: hmm_vec4; r: hmm_vec4): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  res.InternalElementsSSE = mm_div_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_DivideVec4f*(l: hmm_vec4; r: cfloat): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  var Scalar: m128 = mm_set_ps1(r)
  res.InternalElementsSSE = mm_div_ps(l.InternalElementsSSE, Scalar)
  return res

proc HMM_EqualsVec2*(l: hmm_vec2; r: hmm_vec2): hmm_bool {.inline.} =
  var res: hmm_bool = hmm_bool(l.X == r.X and l.Y == r.Y)
  return res

proc HMM_EqualsVec3*(l: hmm_vec3; r: hmm_vec3): hmm_bool {.inline.} =
  var res: hmm_bool = hmm_bool(l.X == r.X and l.Y == r.Y and l.Z == r.Z)
  return res

proc HMM_EqualsVec4*(l: hmm_vec4; r: hmm_vec4): hmm_bool {.inline.} =
  var res: hmm_bool = hmm_bool(l.X == r.X and l.Y == r.Y and l.Z == r.Z and
      l.W == r.W)
  return res

proc HMM_DotVec2*(VecOne: hmm_vec2; VecTwo: hmm_vec2): cfloat {.inline.} =
  var res: cfloat = (VecOne.X * VecTwo.X) + (VecOne.Y * VecTwo.Y)
  return res

proc HMM_DotVec3*(VecOne: hmm_vec3; VecTwo: hmm_vec3): cfloat {.inline.} =
  var res: cfloat = (VecOne.X * VecTwo.X) + (VecOne.Y * VecTwo.Y) +
      (VecOne.Z * VecTwo.Z)
  return res

proc HMM_DotVec4*(VecOne: hmm_vec4; VecTwo: hmm_vec4): cfloat {.inline.} =
  var res: cfloat
  var SSEResultOne: m128 = mm_mul_ps(VecOne.InternalElementsSSE,
                                    VecTwo.InternalElementsSSE)
  var SSEResultTwo: m128 = mm_shuffle_ps(SSEResultOne, SSEResultOne, (
      ((2) shl 6) or ((3) shl 4) or ((0) shl 2) or ((1))))
  SSEResultOne = mm_add_ps(SSEResultOne, SSEResultTwo)
  SSEResultTwo = mm_shuffle_ps(SSEResultOne, SSEResultOne, (
      ((0) shl 6) or ((1) shl 4) or ((2) shl 2) or ((3))))
  SSEResultOne = mm_add_ps(SSEResultOne, SSEResultTwo)
  mm_store_ss(addr(res), SSEResultOne)
  return res

proc HMM_Cross*(VecOne: hmm_vec3; VecTwo: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  res.X = (VecOne.Y * VecTwo.Z) - (VecOne.Z * VecTwo.Y)
  res.Y = (VecOne.Z * VecTwo.X) - (VecOne.X * VecTwo.Z)
  res.Z = (VecOne.X * VecTwo.Y) - (VecOne.Y * VecTwo.X)
  return res

proc HMM_LengthSquaredVec2*(A: hmm_vec2): cfloat {.inline.} =
  var res: cfloat = HMM_DotVec2(A, A)
  return res

proc HMM_LengthSquaredVec3*(A: hmm_vec3): cfloat {.inline.} =
  var res: cfloat = HMM_DotVec3(A, A)
  return res

proc HMM_LengthSquaredVec4*(A: hmm_vec4): cfloat {.inline.} =
  var res: cfloat = HMM_DotVec4(A, A)
  return res

proc HMM_LengthVec2*(A: hmm_vec2): cfloat {.inline.} =
  var res: cfloat = HMM_SquareRootF(HMM_LengthSquaredVec2(A))
  return res

proc HMM_LengthVec3*(A: hmm_vec3): cfloat {.inline.} =
  var res: cfloat = HMM_SquareRootF(HMM_LengthSquaredVec3(A))
  return res

proc HMM_LengthVec4*(A: hmm_vec4): cfloat {.inline.} =
  var res: cfloat = HMM_SquareRootF(HMM_LengthSquaredVec4(A))
  return res

proc HMM_NormalizeVec2*(A: hmm_vec2): hmm_vec2 {.inline.} =
  var res: hmm_vec2
  var VectorLength: cfloat = HMM_LengthVec2(A)
  if VectorLength != 0.0:
    res.X = A.X * (1.0 / VectorLength)
    res.Y = A.Y * (1.0 / VectorLength)
  return res

proc HMM_NormalizeVec3*(A: hmm_vec3): hmm_vec3 {.inline.} =
  var res: hmm_vec3
  var VectorLength: cfloat = HMM_LengthVec3(A)
  if VectorLength != 0.0:
    res.X = A.X * (1.0 / VectorLength)
    res.Y = A.Y * (1.0 / VectorLength)
    res.Z = A.Z * (1.0 / VectorLength)
  return res

proc HMM_NormalizeVec4*(A: hmm_vec4): hmm_vec4 {.inline.} =
  var res: hmm_vec4
  var VectorLength: cfloat = HMM_LengthVec4(A)
  if VectorLength != 0.0:
    var Multiplier: cfloat = 1.0 / VectorLength
    var SSEMultiplier: m128 = mm_set_ps1(Multiplier)
    res.InternalElementsSSE = mm_mul_ps(A.InternalElementsSSE, SSEMultiplier)
  return res

proc HMM_FastNormalizeVec2*(A: hmm_vec2): hmm_vec2 {.inline.} =
  return HMM_MultiplyVec2f(A, HMM_RSquareRootF(HMM_DotVec2(A, A)))

proc HMM_FastNormalizeVec3*(A: hmm_vec3): hmm_vec3 {.inline.} =
  return HMM_MultiplyVec3f(A, HMM_RSquareRootF(HMM_DotVec3(A, A)))

proc HMM_FastNormalizeVec4*(A: hmm_vec4): hmm_vec4 {.inline.} =
  return HMM_MultiplyVec4f(A, HMM_RSquareRootF(HMM_DotVec4(A, A)))

proc HMM_LinearCombineSSE*(l: m128; r: hmm_mat4): m128 {.inline.} =
  var res: m128
  res = mm_mul_ps(mm_shuffle_ps(l, l, 0x00000000), r.Columns[0])
  res = mm_add_ps(res, mm_mul_ps(mm_shuffle_ps(l, l, 0x00000055),
                                      r.Columns[1]))
  res = mm_add_ps(res, mm_mul_ps(mm_shuffle_ps(l, l, 0x000000AA),
                                      r.Columns[2]))
  res = mm_add_ps(res, mm_mul_ps(mm_shuffle_ps(l, l, 0x000000FF),
                                      r.Columns[3]))
  return res

proc HMM_Mat4*(): hmm_mat4 {.inline.} =
  var res: hmm_mat4
  return res

proc HMM_Mat4d*(Diagonal: cfloat): hmm_mat4 {.inline.} =
  var res: hmm_mat4 = HMM_Mat4()
  res.Elements[0][0] = Diagonal
  res.Elements[1][1] = Diagonal
  res.Elements[2][2] = Diagonal
  res.Elements[3][3] = Diagonal
  return res

proc HMM_Transpose*(Matrix: hmm_mat4): hmm_mat4 {.inline.} =
  var res: hmm_mat4 = Matrix
  var
    tmp3: m128
    tmp2: m128
    tmp1: m128
    tmp0: m128
  tmp0 = mm_shuffle_ps((res.Columns[0]), (res.Columns[1]), 0x00000044)
  tmp2 = mm_shuffle_ps((res.Columns[0]), (res.Columns[1]), 0x000000EE)
  tmp1 = mm_shuffle_ps((res.Columns[2]), (res.Columns[3]), 0x00000044)
  tmp3 = mm_shuffle_ps((res.Columns[2]), (res.Columns[3]), 0x000000EE)
  (res.Columns[0]) = mm_shuffle_ps(tmp0, tmp1, 0x00000088)
  (res.Columns[1]) = mm_shuffle_ps(tmp0, tmp1, 0x000000DD)
  (res.Columns[2]) = mm_shuffle_ps(tmp2, tmp3, 0x00000088)
  (res.Columns[3]) = mm_shuffle_ps(tmp2, tmp3, 0x000000DD)
  
  return res

proc HMM_AddMat4*(l: hmm_mat4; r: hmm_mat4): hmm_mat4 {.inline.} =
  var res: hmm_mat4
  res.Columns[0] = mm_add_ps(l.Columns[0], r.Columns[0])
  res.Columns[1] = mm_add_ps(l.Columns[1], r.Columns[1])
  res.Columns[2] = mm_add_ps(l.Columns[2], r.Columns[2])
  res.Columns[3] = mm_add_ps(l.Columns[3], r.Columns[3])
  return res

proc HMM_SubtractMat4*(l: hmm_mat4; r: hmm_mat4): hmm_mat4 {.inline.} =
  var res: hmm_mat4
  res.Columns[0] = mm_sub_ps(l.Columns[0], r.Columns[0])
  res.Columns[1] = mm_sub_ps(l.Columns[1], r.Columns[1])
  res.Columns[2] = mm_sub_ps(l.Columns[2], r.Columns[2])
  res.Columns[3] = mm_sub_ps(l.Columns[3], r.Columns[3])
  return res

proc HMM_MultiplyMat4*(l: hmm_mat4; r: hmm_mat4): hmm_mat4 {.importc: "HMM_MultiplyMat4".}
proc HMM_MultiplyMat4f*(Matrix: hmm_mat4; Scalar: cfloat): hmm_mat4 {.inline.} =
  var res: hmm_mat4
  var SSEScalar: m128 = mm_set_ps1(Scalar)
  res.Columns[0] = mm_mul_ps(Matrix.Columns[0], SSEScalar)
  res.Columns[1] = mm_mul_ps(Matrix.Columns[1], SSEScalar)
  res.Columns[2] = mm_mul_ps(Matrix.Columns[2], SSEScalar)
  res.Columns[3] = mm_mul_ps(Matrix.Columns[3], SSEScalar)
  return res

proc HMM_MultiplyMat4ByVec4*(Matrix: hmm_mat4; v: hmm_vec4): hmm_vec4 {.importc: "HMM_MultiplyMat4ByVec4".}
proc HMM_DivideMat4f*(Matrix: hmm_mat4; Scalar: cfloat): hmm_mat4 {.inline.} =
  var res: hmm_mat4
  var SSEScalar: m128 = mm_set_ps1(Scalar)
  res.Columns[0] = mm_div_ps(Matrix.Columns[0], SSEScalar)
  res.Columns[1] = mm_div_ps(Matrix.Columns[1], SSEScalar)
  res.Columns[2] = mm_div_ps(Matrix.Columns[2], SSEScalar)
  res.Columns[3] = mm_div_ps(Matrix.Columns[3], SSEScalar)
  return res

proc HMM_Orthographic*(l: cfloat; r: cfloat; Bottom: cfloat; Top: cfloat;
                      Near: cfloat; Far: cfloat): hmm_mat4 {.inline.} =
  var res: hmm_mat4 = HMM_Mat4()
  res.Elements[0][0] = 2.0 / (r - l)
  res.Elements[1][1] = 2.0 / (Top - Bottom)
  res.Elements[2][2] = 2.0 / (Near - Far)
  res.Elements[3][3] = 1.0
  res.Elements[3][0] = (l + r) / (l - r)
  res.Elements[3][1] = (Bottom + Top) / (Bottom - Top)
  res.Elements[3][2] = (Far + Near) / (Near - Far)
  return res

proc HMM_Perspective*(FOV: cfloat; AspectRatio: cfloat; Near: cfloat; Far: cfloat): hmm_mat4 {.
    inline.} =
  var res: hmm_mat4 = HMM_Mat4()
  var Cotangent: cfloat = 1.0 / HMM_TanF(FOV * (3.14159265359 / 360.0))
  res.Elements[0][0] = Cotangent / AspectRatio
  res.Elements[1][1] = Cotangent
  res.Elements[2][3] = -1.0
  res.Elements[2][2] = (Near + Far) / (Near - Far)
  res.Elements[3][2] = (2.0 * Near * Far) / (Near - Far)
  res.Elements[3][3] = 0.0
  return res

proc HMM_Translate*(Translation: hmm_vec3): hmm_mat4 {.inline.} =
  var res: hmm_mat4 = HMM_Mat4d(1.0)
  res.Elements[3][0] = Translation.X
  res.Elements[3][1] = Translation.Y
  res.Elements[3][2] = Translation.Z
  return res

proc HMM_Rotate*(Angle: cfloat; Axis: hmm_vec3): hmm_mat4 {.importc: "HMM_Rotate".}
proc HMM_Scale*(Scale: hmm_vec3): hmm_mat4 {.inline.} =
  var res: hmm_mat4 = HMM_Mat4d(1.0)
  res.Elements[0][0] = Scale.X
  res.Elements[1][1] = Scale.Y
  res.Elements[2][2] = Scale.Z
  return res

proc HMM_LookAt*(Eye: hmm_vec3; Center: hmm_vec3; Up: hmm_vec3): hmm_mat4 {.importc: "HMM_LookAt".}
proc HMM_Quaternion*(X: cfloat; Y: cfloat; Z: cfloat; W: cfloat): hmm_quaternion {.inline.} =
  var res: hmm_quaternion
  res.InternalElementsSSE = mm_setr_ps(X, Y, Z, W)
  return res

proc HMM_QuaternionV4*(v: hmm_vec4): hmm_quaternion {.inline.} =
  var res: hmm_quaternion
  res.InternalElementsSSE = v.InternalElementsSSE
  return res

proc HMM_AddQuaternion*(l: hmm_quaternion; r: hmm_quaternion): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  res.InternalElementsSSE = mm_add_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_SubtractQuaternion*(l: hmm_quaternion; r: hmm_quaternion): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  res.InternalElementsSSE = mm_sub_ps(l.InternalElementsSSE,
                                        r.InternalElementsSSE)
  return res

proc HMM_MultiplyQuaternion*(l: hmm_quaternion; r: hmm_quaternion): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  var SSEResultOne: m128 = mm_xor_ps(mm_shuffle_ps(l.InternalElementsSSE,
      l.InternalElementsSSE,
      (((0) shl 6) or ((0) shl 4) or ((0) shl 2) or ((0)))),
                                    mm_setr_ps(0.0, -0.0, 0.0, -0.0))
  var SSEResultTwo: m128 = mm_shuffle_ps(r.InternalElementsSSE,
                                        r.InternalElementsSSE, (
      ((0) shl 6) or ((1) shl 4) or ((2) shl 2) or ((3))))
  var SSEResultThree: m128 = mm_mul_ps(SSEResultTwo, SSEResultOne)
  SSEResultOne = mm_xor_ps(mm_shuffle_ps(l.InternalElementsSSE,
      l.InternalElementsSSE,
      (((1) shl 6) or ((1) shl 4) or ((1) shl 2) or ((1)))),
                          mm_setr_ps(0.0, 0.0, -0.0, -0.0))
  SSEResultTwo = mm_shuffle_ps(r.InternalElementsSSE,
                              r.InternalElementsSSE, (
      ((1) shl 6) or ((0) shl 4) or ((3) shl 2) or ((2))))
  SSEResultThree = mm_add_ps(SSEResultThree,
                            mm_mul_ps(SSEResultTwo, SSEResultOne))
  SSEResultOne = mm_xor_ps(mm_shuffle_ps(l.InternalElementsSSE,
      l.InternalElementsSSE,
      (((2) shl 6) or ((2) shl 4) or ((2) shl 2) or ((2)))),
                          mm_setr_ps(-0.0, 0.0, 0.0, -0.0))
  SSEResultTwo = mm_shuffle_ps(r.InternalElementsSSE,
                              r.InternalElementsSSE, (
      ((2) shl 6) or ((3) shl 4) or ((0) shl 2) or ((1))))
  SSEResultThree = mm_add_ps(SSEResultThree,
                            mm_mul_ps(SSEResultTwo, SSEResultOne))
  SSEResultOne = mm_shuffle_ps(l.InternalElementsSSE, l.InternalElementsSSE, (
      ((3) shl 6) or ((3) shl 4) or ((3) shl 2) or ((3))))
  SSEResultTwo = mm_shuffle_ps(r.InternalElementsSSE,
                              r.InternalElementsSSE, (
      ((3) shl 6) or ((2) shl 4) or ((1) shl 2) or ((0))))
  res.InternalElementsSSE = mm_add_ps(SSEResultThree,
                                        mm_mul_ps(SSEResultTwo, SSEResultOne))
  return res

proc HMM_MultiplyQuaternionF*(l: hmm_quaternion; Multiplicative: cfloat): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  var Scalar: m128 = mm_set_ps1(Multiplicative)
  res.InternalElementsSSE = mm_mul_ps(l.InternalElementsSSE, Scalar)
  return res

proc HMM_DivideQuaternionF*(l: hmm_quaternion; Dividend: cfloat): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  var Scalar: m128 = mm_set_ps1(Dividend)
  res.InternalElementsSSE = mm_div_ps(l.InternalElementsSSE, Scalar)
  return res

proc HMM_InverseQuaternion*(l: hmm_quaternion): hmm_quaternion {.importc: "HMM_InverseQuaternion".}
proc HMM_DotQuaternion*(l: hmm_quaternion; r: hmm_quaternion): cfloat {.inline.} =
  var res: cfloat
  var SSEResultOne: m128 = mm_mul_ps(l.InternalElementsSSE,
                                    r.InternalElementsSSE)
  var SSEResultTwo: m128 = mm_shuffle_ps(SSEResultOne, SSEResultOne, (
      ((2) shl 6) or ((3) shl 4) or ((0) shl 2) or ((1))))
  SSEResultOne = mm_add_ps(SSEResultOne, SSEResultTwo)
  SSEResultTwo = mm_shuffle_ps(SSEResultOne, SSEResultOne, (
      ((0) shl 6) or ((1) shl 4) or ((2) shl 2) or ((3))))
  SSEResultOne = mm_add_ps(SSEResultOne, SSEResultTwo)
  mm_store_ss(addr(res), SSEResultOne)
  return res

proc HMM_NormalizeQuaternion*(l: hmm_quaternion): hmm_quaternion {.inline.} =
  var res: hmm_quaternion
  var Length: cfloat = HMM_SquareRootF(HMM_DotQuaternion(l, l))
  res = HMM_DivideQuaternionF(l, Length)
  return res

proc HMM_NLerp*(l: hmm_quaternion; Time: cfloat; r: hmm_quaternion): hmm_quaternion {.
    inline.} =
  var res: hmm_quaternion
  var ScalarLeft: m128 = mm_set_ps1(1.0 - Time)
  var ScalarRight: m128 = mm_set_ps1(Time)
  var SSEResultOne: m128 = mm_mul_ps(l.InternalElementsSSE, ScalarLeft)
  var SSEResultTwo: m128 = mm_mul_ps(r.InternalElementsSSE, ScalarRight)
  res.InternalElementsSSE = mm_add_ps(SSEResultOne, SSEResultTwo)
  res = HMM_NormalizeQuaternion(res)
  return res

proc HMM_Slerp*(l: hmm_quaternion; Time: cfloat; r: hmm_quaternion): hmm_quaternion {.importc: "HMM_Slerp".}
proc HMM_QuaternionToMat4*(l: hmm_quaternion): hmm_mat4 {.importc: "HMM_QuaternionToMat4".}
proc HMM_Mat4ToQuaternion*(l: hmm_mat4): hmm_quaternion {.importc: "HMM_Mat4ToQuaternion".}
proc HMM_QuaternionFromAxisAngle*(Axis: hmm_vec3; AngleOfRotation: cfloat): hmm_quaternion {.importc: "HMM_QuaternionFromAxisAngle".}