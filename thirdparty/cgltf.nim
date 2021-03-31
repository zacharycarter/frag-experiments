{.compile: "cgltf.c".}

type
  INNER_C_UNION_cgltf_pp_504* {.bycopy, union.} = object
    perspective*: cgltf_camera_perspective
    orthographic*: cgltf_camera_orthographic

  cgltf_size* = int
  cgltf_float* = float32
  cgltf_int* = int32
  cgltf_uint* = uint32
  cgltf_bool* = int32
  cgltf_file_type* {.size: sizeof(int32).} = enum
    cgltf_file_type_invalid, cgltf_file_type_gltf, cgltf_file_type_glb
  cgltf_result* {.size: sizeof(int32).} = enum
    cgltf_result_success, cgltf_result_data_too_short,
    cgltf_result_unknown_format, cgltf_result_invalid_json,
    cgltf_result_invalid_gltf, cgltf_result_invalid_options,
    cgltf_result_file_not_found, cgltf_result_io_error,
    cgltf_result_out_of_memory, cgltf_result_legacy_gltf
  cgltf_memory_options* {.bycopy.} = object
    alloc*: proc (user: pointer; size: cgltf_size): pointer {.cdecl.}
    free*: proc (user: pointer; `ptr`: pointer) {.cdecl.}
    user_data*: pointer

  cgltf_file_options* {.bycopy.} = object
    read*: proc (memory_options: ptr cgltf_memory_options;
                                 file_options: ptr cgltf_file_options;
                                 path: cstring; size: ptr cgltf_size;
                                 data: ptr pointer): cgltf_result {.cdecl.}
    release*: proc (memory_options: ptr cgltf_memory_options;
                                       file_options: ptr cgltf_file_options;
                                       data: pointer) {.cdecl.}
    user_data*: pointer

  cgltf_options* {.bycopy.} = object
    `type`*: cgltf_file_type
    json_token_count*: cgltf_size
    memory*: cgltf_memory_options
    file*: cgltf_file_options

  cgltf_buffer_view_type* {.size: sizeof(int32).} = enum
    cgltf_buffer_view_type_invalid, cgltf_buffer_view_type_indices,
    cgltf_buffer_view_type_vertices
  cgltf_attribute_type* {.size: sizeof(int32).} = enum
    cgltf_attribute_type_invalid, cgltf_attribute_type_position,
    cgltf_attribute_type_normal, cgltf_attribute_type_tangent,
    cgltf_attribute_type_texcoord, cgltf_attribute_type_color,
    cgltf_attribute_type_joints, cgltf_attribute_type_weights
  cgltf_component_type* {.size: sizeof(int32).} = enum
    cgltf_component_type_invalid, cgltf_component_type_r_8,
    cgltf_component_type_r_8u, cgltf_component_type_r_16,
    cgltf_component_type_r_16u, cgltf_component_type_r_32u,
    cgltf_component_type_r_32f
  cgltf_type* {.size: sizeof(int32).} = enum
    cgltf_type_invalid, cgltf_type_scalar, cgltf_type_vec2, cgltf_type_vec3,
    cgltf_type_vec4, cgltf_type_mat2, cgltf_type_mat3, cgltf_type_mat4
  cgltf_primitive_type* {.size: sizeof(int32).} = enum
    cgltf_primitive_type_points, cgltf_primitive_type_lines,
    cgltf_primitive_type_line_loop, cgltf_primitive_type_line_strip,
    cgltf_primitive_type_triangles, cgltf_primitive_type_triangle_strip,
    cgltf_primitive_type_triangle_fan
  cgltf_alpha_mode* {.size: sizeof(int32).} = enum
    cgltf_alpha_mode_opaque, cgltf_alpha_mode_mask, cgltf_alpha_mode_blend
  cgltf_animation_path_type* {.size: sizeof(int32).} = enum
    cgltf_animation_path_type_invalid, cgltf_animation_path_type_translation,
    cgltf_animation_path_type_rotation, cgltf_animation_path_type_scale,
    cgltf_animation_path_type_weights
  cgltf_interpolation_type* {.size: sizeof(int32).} = enum
    cgltf_interpolation_type_linear, cgltf_interpolation_type_step,
    cgltf_interpolation_type_cubic_spline
  cgltf_camera_type* {.size: sizeof(int32).} = enum
    cgltf_camera_type_invalid, cgltf_camera_type_perspective,
    cgltf_camera_type_orthographic
  cgltf_light_type* {.size: sizeof(int32).} = enum
    cgltf_light_type_invalid, cgltf_light_type_directional,
    cgltf_light_type_point, cgltf_light_type_spot
  cgltf_extras* {.bycopy.} = object
    start_offset*: cgltf_size
    end_offset*: cgltf_size

  cgltf_extension* {.bycopy.} = object
    name*: cstring
    data*: cstring

  cgltf_buffer* {.bycopy.} = object
    name*: cstring
    size*: cgltf_size
    uri*: cstring
    data*: pointer
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_meshopt_compression_mode* {.size: sizeof(int32).} = enum
    cgltf_meshopt_compression_mode_invalid,
    cgltf_meshopt_compression_mode_attributes,
    cgltf_meshopt_compression_mode_triangles,
    cgltf_meshopt_compression_mode_indices
  cgltf_meshopt_compression_filter* {.size: sizeof(int32).} = enum
    cgltf_meshopt_compression_filter_none,
    cgltf_meshopt_compression_filter_octahedral,
    cgltf_meshopt_compression_filter_quaternion,
    cgltf_meshopt_compression_filter_exponential
  cgltf_meshopt_compression* {.bycopy.} = object
    buffer*: ptr cgltf_buffer
    offset*: cgltf_size
    size*: cgltf_size
    stride*: cgltf_size
    count*: cgltf_size
    mode*: cgltf_meshopt_compression_mode
    filter*: cgltf_meshopt_compression_filter

  cgltf_buffer_view* {.bycopy.} = object
    name*: cstring
    buffer*: ptr cgltf_buffer
    offset*: cgltf_size
    size*: cgltf_size
    stride*: cgltf_size
    `type`*: cgltf_buffer_view_type
    data*: pointer
    has_meshopt_compression*: cgltf_bool
    meshopt_compression*: cgltf_meshopt_compression
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_accessor_sparse* {.bycopy.} = object
    count*: cgltf_size
    indices_buffer_view*: ptr cgltf_buffer_view
    indices_byte_offset*: cgltf_size
    indices_component_type*: cgltf_component_type
    values_buffer_view*: ptr cgltf_buffer_view
    values_byte_offset*: cgltf_size
    extras*: cgltf_extras
    indices_extras*: cgltf_extras
    values_extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension
    indices_extensions_count*: cgltf_size
    indices_extensions*: ptr cgltf_extension
    values_extensions_count*: cgltf_size
    values_extensions*: ptr cgltf_extension

  cgltf_accessor* {.bycopy.} = object
    name*: cstring
    component_type*: cgltf_component_type
    normalized*: cgltf_bool
    `type`*: cgltf_type
    offset*: cgltf_size
    count*: cgltf_size
    stride*: cgltf_size
    buffer_view*: ptr cgltf_buffer_view
    has_min*: cgltf_bool
    min*: array[16, cgltf_float]
    has_max*: cgltf_bool
    max*: array[16, cgltf_float]
    is_sparse*: cgltf_bool
    sparse*: cgltf_accessor_sparse
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_attribute* {.bycopy.} = object
    name*: cstring
    `type`*: cgltf_attribute_type
    index*: cgltf_int
    data*: ptr cgltf_accessor

  cgltf_image* {.bycopy.} = object
    name*: cstring
    uri*: cstring
    buffer_view*: ptr cgltf_buffer_view
    mime_type*: cstring
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_sampler* {.bycopy.} = object
    name*: cstring
    mag_filter*: cgltf_int
    min_filter*: cgltf_int
    wrap_s*: cgltf_int
    wrap_t*: cgltf_int
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_texture* {.bycopy.} = object
    name*: cstring
    image*: ptr cgltf_image
    sampler*: ptr cgltf_sampler
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_texture_transform* {.bycopy.} = object
    offset*: array[2, cgltf_float]
    rotation*: cgltf_float
    scale*: array[2, cgltf_float]
    texcoord*: cgltf_int

  cgltf_texture_view* {.bycopy.} = object
    texture*: ptr cgltf_texture
    texcoord*: cgltf_int
    scale*: cgltf_float
    has_transform*: cgltf_bool
    transform*: cgltf_texture_transform
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_pbr_metallic_roughness* {.bycopy.} = object
    base_color_texture*: cgltf_texture_view
    metallic_roughness_texture*: cgltf_texture_view
    base_color_factor*: array[4, cgltf_float]
    metallic_factor*: cgltf_float
    roughness_factor*: cgltf_float
    extras*: cgltf_extras

  cgltf_pbr_specular_glossiness* {.bycopy.} = object
    diffuse_texture*: cgltf_texture_view
    specular_glossiness_texture*: cgltf_texture_view
    diffuse_factor*: array[4, cgltf_float]
    specular_factor*: array[3, cgltf_float]
    glossiness_factor*: cgltf_float

  cgltf_clearcoat* {.bycopy.} = object
    clearcoat_texture*: cgltf_texture_view
    clearcoat_roughness_texture*: cgltf_texture_view
    clearcoat_normal_texture*: cgltf_texture_view
    clearcoat_factor*: cgltf_float
    clearcoat_roughness_factor*: cgltf_float

  cgltf_transmission* {.bycopy.} = object
    transmission_texture*: cgltf_texture_view
    transmission_factor*: cgltf_float

  cgltf_ior* {.bycopy.} = object
    ior*: cgltf_float

  cgltf_specular* {.bycopy.} = object
    specular_texture*: cgltf_texture_view
    specular_color_texture*: cgltf_texture_view
    specular_color_factor*: array[3,
        cgltf_float]
    specular_factor*: cgltf_float

  cgltf_volume* {.bycopy.} = object
    thickness_texture*: cgltf_texture_view
    thickness_factor*: cgltf_float
    attenuation_color*: array[3, cgltf_float]
    attenuation_distance*: cgltf_float

  cgltf_sheen* {.bycopy.} = object
    sheen_color_texture*: cgltf_texture_view
    sheen_color_factor*: array[3, cgltf_float]
    sheen_roughness_texture*: cgltf_texture_view
    sheen_roughness_factor*: cgltf_float

  cgltf_material* {.bycopy.} = object
    name*: cstring
    has_pbr_metallic_roughness*: cgltf_bool
    has_pbr_specular_glossiness*: cgltf_bool
    has_clearcoat*: cgltf_bool
    has_transmission*: cgltf_bool
    has_volume*: cgltf_bool
    has_ior*: cgltf_bool
    has_specular*: cgltf_bool
    has_sheen*: cgltf_bool
    pbr_metallic_roughness*: cgltf_pbr_metallic_roughness
    pbr_specular_glossiness*: cgltf_pbr_specular_glossiness
    clearcoat*: cgltf_clearcoat
    ior*: cgltf_ior
    specular*: cgltf_specular
    sheen*: cgltf_sheen
    transmission*: cgltf_transmission
    volume*: cgltf_volume
    normal_texture*: cgltf_texture_view
    occlusion_texture*: cgltf_texture_view
    emissive_texture*: cgltf_texture_view
    emissive_factor*: array[3, cgltf_float]
    alpha_mode*: cgltf_alpha_mode
    alpha_cutoff*: cgltf_float
    double_sided*: cgltf_bool
    unlit*: cgltf_bool
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_material_mapping* {.bycopy.} = object
    variant*: cgltf_size
    material*: ptr cgltf_material
    extras*: cgltf_extras

  cgltf_morph_target* {.bycopy.} = object
    attributes*: ptr cgltf_attribute
    attributes_count*: cgltf_size

  cgltf_draco_mesh_compression* {.bycopy.} = object
    buffer_view*: ptr cgltf_buffer_view
    attributes*: ptr cgltf_attribute
    attributes_count*: cgltf_size

  cgltf_primitive* {.bycopy.} = object
    `type`*: cgltf_primitive_type
    indices*: ptr cgltf_accessor
    material*: ptr cgltf_material
    attributes*: ptr cgltf_attribute
    attributes_count*: cgltf_size
    targets*: ptr cgltf_morph_target
    targets_count*: cgltf_size
    extras*: cgltf_extras
    has_draco_mesh_compression*: cgltf_bool
    draco_mesh_compression*: cgltf_draco_mesh_compression
    mappings*: ptr cgltf_material_mapping
    mappings_count*: cgltf_size
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_mesh* {.bycopy.} = object
    name*: cstring
    primitives*: ptr cgltf_primitive
    primitives_count*: cgltf_size
    weights*: ptr cgltf_float
    weights_count*: cgltf_size
    target_names*: cstringArray
    target_names_count*: cgltf_size
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_skin* {.bycopy.} = object
    name*: cstring
    joints*: ptr ptr cgltf_node
    joints_count*: cgltf_size
    skeleton*: ptr cgltf_node
    inverse_bind_matrices*: ptr cgltf_accessor
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_camera_perspective* {.bycopy.} = object
    has_aspect_ratio*: cgltf_bool
    aspect_ratio*: cgltf_float
    yfov*: cgltf_float
    has_zfar*: cgltf_bool
    zfar*: cgltf_float
    znear*: cgltf_float
    extras*: cgltf_extras

  cgltf_camera_orthographic* {.bycopy.} = object
    xmag*: cgltf_float
    ymag*: cgltf_float
    zfar*: cgltf_float
    znear*: cgltf_float
    extras*: cgltf_extras

  cgltf_camera* {.bycopy.} = object
    name*: cstring
    `type`*: cgltf_camera_type
    data*: INNER_C_UNION_cgltf_pp_504
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_light* {.bycopy.} = object
    name*: cstring
    color*: array[3, cgltf_float]
    intensity*: cgltf_float
    `type`*: cgltf_light_type
    range*: cgltf_float
    spot_inner_cone_angle*: cgltf_float
    spot_outer_cone_angle*: cgltf_float

  cgltf_node* {.bycopy.} = object
    name*: cstring
    parent*: ptr cgltf_node
    children*: ptr ptr cgltf_node
    children_count*: cgltf_size
    skin*: ptr cgltf_skin
    mesh*: ptr cgltf_mesh
    camera*: ptr cgltf_camera
    light*: ptr cgltf_light
    weights*: ptr cgltf_float
    weights_count*: cgltf_size
    has_translation*: cgltf_bool
    has_rotation*: cgltf_bool
    has_scale*: cgltf_bool
    has_matrix*: cgltf_bool
    translation*: array[3, cgltf_float]
    rotation*: array[4, cgltf_float]
    scale*: array[3, cgltf_float]
    matrix*: array[16, cgltf_float]
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_scene* {.bycopy.} = object
    name*: cstring
    nodes*: ptr ptr cgltf_node
    nodes_count*: cgltf_size
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_animation_sampler* {.bycopy.} = object
    input*: ptr cgltf_accessor
    output*: ptr cgltf_accessor
    interpolation*: cgltf_interpolation_type
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_animation_channel* {.bycopy.} = object
    sampler*: ptr cgltf_animation_sampler
    target_node*: ptr cgltf_node
    target_path*: cgltf_animation_path_type
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_animation* {.bycopy.} = object
    name*: cstring
    samplers*: ptr cgltf_animation_sampler
    samplers_count*: cgltf_size
    channels*: ptr cgltf_animation_channel
    channels_count*: cgltf_size
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_material_variant* {.bycopy.} = object
    name*: cstring
    extras*: cgltf_extras

  cgltf_asset* {.bycopy.} = object
    copyright*: cstring
    generator*: cstring
    version*: cstring
    min_version*: cstring
    extras*: cgltf_extras
    extensions_count*: cgltf_size
    extensions*: ptr cgltf_extension

  cgltf_data* {.bycopy.} = object
    file_type*: cgltf_file_type
    file_data*: pointer
    asset*: cgltf_asset
    meshes*: ptr cgltf_mesh
    meshes_count*: cgltf_size
    materials*: ptr cgltf_material
    materials_count*: cgltf_size
    accessors*: ptr cgltf_accessor
    accessors_count*: cgltf_size
    buffer_views*: ptr cgltf_buffer_view
    buffer_views_count*: cgltf_size
    buffers*: ptr cgltf_buffer
    buffers_count*: cgltf_size
    images*: ptr cgltf_image
    images_count*: cgltf_size
    textures*: ptr cgltf_texture
    textures_count*: cgltf_size
    samplers*: ptr cgltf_sampler
    samplers_count*: cgltf_size
    skins*: ptr cgltf_skin
    skins_count*: cgltf_size
    cameras*: ptr cgltf_camera
    cameras_count*: cgltf_size
    lights*: ptr cgltf_light
    lights_count*: cgltf_size
    nodes*: ptr cgltf_node
    nodes_count*: cgltf_size
    scenes*: ptr cgltf_scene
    scenes_count*: cgltf_size
    scene*: ptr cgltf_scene
    animations*: ptr cgltf_animation
    animations_count*: cgltf_size
    variants*: ptr cgltf_material_variant
    variants_count*: cgltf_size
    extras*: cgltf_extras
    data_extensions_count*: cgltf_size
    data_extensions*: ptr cgltf_extension
    extensions_used*: cstringArray
    extensions_used_count*: cgltf_size
    extensions_required*: cstringArray
    extensions_required_count*: cgltf_size
    json*: cstring
    json_size*: cgltf_size
    bin*: pointer
    bin_size*: cgltf_size
    memory*: cgltf_memory_options
    file*: cgltf_file_options

proc cgltf_parse*(options: ptr cgltf_options; data: pointer; size: cgltf_size;
                 out_data: ptr ptr cgltf_data): cgltf_result {.cdecl,
    importc: "cgltf_parse".}
proc cgltf_parse_file*(options: ptr cgltf_options; path: cstring;
                      out_data: ptr ptr cgltf_data): cgltf_result {.cdecl,
    importc: "cgltf_parse_file".}
proc cgltf_load_buffers*(options: ptr cgltf_options; data: ptr cgltf_data;
                        gltf_path: cstring): cgltf_result {.cdecl,
    importc: "cgltf_load_buffers".}
proc cgltf_load_buffer_base64*(options: ptr cgltf_options; size: cgltf_size;
                              base64: cstring; out_data: ptr pointer): cgltf_result {.
    cdecl, importc: "cgltf_load_buffer_base64".}
proc cgltf_decode_uri*(uri: cstring) {.cdecl, importc: "cgltf_decode_uri".}
proc cgltf_validate*(data: ptr cgltf_data): cgltf_result {.cdecl,
    importc: "cgltf_validate".}
proc cgltf_free*(data: ptr cgltf_data) {.cdecl, importc: "cgltf_free".}
proc cgltf_node_transform_local*(node: ptr cgltf_node; out_matrix: ptr cgltf_float) {.
    cdecl, importc: "cgltf_node_transform_local".}
proc cgltf_node_transform_world*(node: ptr cgltf_node; out_matrix: ptr cgltf_float) {.
    cdecl, importc: "cgltf_node_transform_world".}
proc cgltf_accessor_read_float*(accessor: ptr cgltf_accessor; index: cgltf_size;
                               `out`: ptr cgltf_float; element_size: cgltf_size): cgltf_bool {.
    cdecl, importc: "cgltf_accessor_read_float".}
proc cgltf_accessor_read_uint*(accessor: ptr cgltf_accessor; index: cgltf_size;
                              `out`: ptr cgltf_uint; element_size: cgltf_size): cgltf_bool {.
    cdecl, importc: "cgltf_accessor_read_uint".}
proc cgltf_accessor_read_index*(accessor: ptr cgltf_accessor; index: cgltf_size): cgltf_size {.
    cdecl, importc: "cgltf_accessor_read_index".}
proc cgltf_num_components*(`type`: cgltf_type): cgltf_size {.cdecl,
    importc: "cgltf_num_components".}
proc cgltf_accessor_unpack_floats*(accessor: ptr cgltf_accessor;
                                  `out`: ptr cgltf_float; float_count: cgltf_size): cgltf_size {.
    cdecl, importc: "cgltf_accessor_unpack_floats".}
proc cgltf_copy_extras_json*(data: ptr cgltf_data; extras: ptr cgltf_extras;
                            dest: cstring; dest_size: ptr cgltf_size): cgltf_result {.
    cdecl, importc: "cgltf_copy_extras_json".}