@ctype mat4 hmm_mat4

@vs vs
uniform vs_params {
    mat4 model;
    mat4 view_proj;
    vec3 eye_pos;
};

layout(location=0) in vec4 position;
layout(location=1) in vec3 normal;
layout(location=2) in vec2 texcoord;

out vec3 v_pos;
out vec3 v_nrm;
out vec2 v_uv;
out vec3 v_eye_pos;

void main() {
    vec4 pos = model * position;
    v_pos = pos.xyz / pos.w;
    v_nrm = (model * vec4(normal, 0.0)).xyz;
    v_uv = texcoord;
    v_eye_pos = eye_pos;
    gl_Position = view_proj * pos;
}
@end

@fs fs
in vec3 v_pos;
in vec3 v_nrm;
in vec2 v_uv;
in vec3 v_eye_pos;

out vec4 FragColor;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main() {
    // FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), 0.2);
    FragColor = vec4(1.0, 0.0, 0.0, 1.0);
}
@end

@program simple vs fs