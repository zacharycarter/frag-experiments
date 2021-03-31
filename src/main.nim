import shaders/simple, gfx/model,
       ../thirdparty/[hmm, sokol]

type
  State = object
    model: Model
    pipeline: sg_pipeline
    bindings: sg_bindings
    passAction: sg_pass_action

var
  state: State 
  vertices* = [-0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 0.0'f32, 0.5'f32, -0.5'f32, -0.5'f32, 1.0'f32,
                    0.0'f32, 0.5'f32, 0.5'f32, -0.5'f32, 1.0'f32, 1.0'f32, 0.5'f32, 0.5'f32, -0.5'f32, 1.0'f32,
                    1.0'f32, -0.5'f32, 0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32, -0.5'f32, -0.5'f32, -0.5'f32,
                    0.0'f32, 0.0'f32, -0.5'f32, -0.5'f32, 0.5'f32, 0.0'f32, 0.0'f32, 0.5'f32, -0.5'f32, 0.5'f32,
                    1.0'f32, 0.0'f32, 0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 1.0'f32, 0.5'f32, 0.5'f32, 0.5'f32,
                    1.0'f32, 1.0'f32, -0.5'f32, 0.5'f32, 0.5'f32, 0.0'f32, 1.0'f32, -0.5'f32, -0.5'f32, 0.5'f32,
                    0.0'f32, 0.0'f32, -0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32, -0.5'f32, 0.5'f32,
                    -0.5'f32, 1.0'f32, 1.0'f32, -0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32, -0.5'f32,
                    -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32, -0.5'f32, -0.5'f32, 0.5'f32, 0.0'f32, 0.0'f32,
                    -0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32, 0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32,
                    0.5'f32, 0.5'f32, -0.5'f32, 1.0'f32, 1.0'f32, 0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32,
                    0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32, 0.5'f32, -0.5'f32, 0.5'f32, 0.0'f32, 0.0'f32,
                    0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32, -0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32,
                    0.5'f32, -0.5'f32, -0.5'f32, 1.0'f32, 1.0'f32, 0.5'f32, -0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32,
                    0.5'f32, -0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32, -0.5'f32, -0.5'f32, 0.5'f32, 0.0'f32, 0.0'f32,
                    -0.5'f32, -0.5'f32, -0.5'f32, 0.0'f32, 1.0'f32, -0.5'f32, 0.5'f32, -0.5'f32, 0.0'f32,
                    1.0'f32, 0.5'f32, 0.5'f32, -0.5'f32, 1.0'f32, 1.0'f32, 0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32,
                    0.0'f32, 0.5'f32, 0.5'f32, 0.5'f32, 1.0'f32, 0.0'f32, -0.5'f32, 0.5'f32, 0.5'f32, 0.0'f32,
                    0.0'f32, -0.5'f32, 0.5'f32, -0.5'f32, 0.0'f32, 1.0]


proc init() {.cdecl.} =
  var sgDesc = sg_desc(
    context: sapp_sgcontext()
  )
  sg_setup(addr(sgDesc))

  state.model = loadModelFromFile("./assets/models/DamagedHelmet.glb")

  var 
    vertexBufferDesc = sg_buffer_desc(
      data: sg_range(
        `ptr`: addr(state.model.vertices[0]),
        size: int32(len(state.model.vertices) * 12 * sizeof(float32)),
      ),
      usage: SG_USAGE_IMMUTABLE,
      label: "model-vertices"
    )

    indexBufferDesc = sg_buffer_desc(
      data: sg_range(
        `ptr`: addr(state.model.indices[0]),
        size: int32(len(state.model.indices) * 2 * sizeof(uint16)),
      ),
      `type`: SG_BUFFERTYPE_INDEXBUFFER,
      usage: SG_USAGE_IMMUTABLE,
      label: "model-indices"
    )
  
  state.bindings.vertex_buffers[0] = sg_make_buffer(
    addr(vertexBufferDesc)
  )
  state.bindings.index_buffer = sg_make_buffer(
    addr(indexBufferDesc)
  )

  let shd = sg_make_shader(simple_shader_desc(sg_query_backend()))

  var pipelineDesc = sg_pipeline_desc(
    shader: shd,
    label: "triangle-pipeline",
    index_type: SG_INDEXTYPE_UINT16
  )
  pipelineDesc.layout.attrs[ATTR_vs_position].format = SG_VERTEXFORMAT_FLOAT4
  pipelineDesc.layout.attrs[ATTR_vs_normal].format = SG_VERTEXFORMAT_FLOAT3
  pipelineDesc.layout.attrs[ATTR_vs_texcoord].format = SG_VERTEXFORMAT_FLOAT2
  pipelineDesc.depth.compare = SG_COMPAREFUNC_LESS_EQUAL
  pipelineDesc.depth.write_enabled = true
  
  state.pipeline = sg_make_pipeline(addr(pipelineDesc))

  state.passAction.colors[0] = sg_color_attachment_action(
    action: SG_ACTION_CLEAR,
    value: sg_color(r: 0.3'f32, g: 0.3'f32, b: 0.3'f32, a: 1.0'f32)
  )

proc update() {.cdecl.} =
  let
    model = HMM_Rotate(50.0'f32, HMM_Vec3(0.5'f32, 1.0'f32, 0.0'f32))
    view = HMM_Translate(HMM_Vec3(0.0'f32, 0.0'f32, -100.0'f32))
    projection = HMM_Perspective(45.0'f32, 960.0'f32 / 540.0'f32, 0.1'f32, 100.0'f32)
  
  sg_begin_default_pass(addr(state.passAction), sapp_width(), sapp_height())
  sg_apply_pipeline(state.pipeline)
  sg_apply_bindings(addr(state.bindings))

  var 
    vsp {.align(16).} = vs_params_t(
      model: model,
      viewProj: HMM_MultiplyMat4(view, projection),
      eyePos: [0.0'f32, 0.0'f32, -100.0'f32]
    )
    vsdata = sg_range(`ptr`: addr(vsp), size: int32(sizeof(vsp)))
  sg_apply_uniforms(SG_SHADERSTAGE_VS, SLOT_vs_params, addr(vsdata))

  sg_draw(0, int32(len(state.model.vertices) div 3), 1)
  sg_end_pass()
  sg_commit()

proc shutdown() {.cdecl.} =
  echo "shutting down"

proc entry() =
  var appDesc = sapp_desc(
    init_cb: init,
    frame_cb: update,
    cleanup_cb: shutdown,
    width: 960,
    height: 500,
    window_title: "Clear Sample",
  )
  sapp_run(addr(appDesc))

when isMainModule:
  echo "main"
  entry()