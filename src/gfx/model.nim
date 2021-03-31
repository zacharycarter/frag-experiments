import mesh,
       ../../thirdparty/cgltf

type
  Model* = object
    meshes: seq[Mesh]

    indices*: seq[uint16]
    vertices*: seq[float32]

proc loadModelFromFile*(filename: string): Model =
  var
    options = cgltf_options(`type`: cgltf_file_type_glb)
    data: ptr cgltf_data
    success = cgltf_parse_file(addr(options), filename, addr(data))
  
  if success == cgltf_result_success:
    success = cgltf_load_buffers(addr(options), data, filename)
  
  result.meshes.setLen(data.meshes_count)

  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].`type`
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].name
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].component_type
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].normalized
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].offset
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].count
  echo cast[ptr UncheckedArray[cgltf_accessor]](data.accessors)[0].stride

  for i in 0 ..< data.buffer_views_count:
    let 
      bv = cast[ptr UncheckedArray[cgltf_buffer_view]](data.buffer_views)[i]
    if bv.`type` == cgltf_buffer_view_type_vertices:
      let bvd = cast[ptr UncheckedArray[float32]](bv.buffer.data)
      add(result.vertices, toOpenArray(bvd, bv.offset, bv.offset + (bv.size - 1)))
    elif bv.`type` == cgltf_buffer_view_type_indices:
      let bvd = cast[ptr UncheckedArray[uint16]](bv.buffer.data)
      add(result.indices, toOpenArray(bvd, bv.offset, bv.offset + (bv.size - 1)))

  cgltf_free(data)
