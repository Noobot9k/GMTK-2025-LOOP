#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(r16f, set = 0, binding = 0) uniform restrict readonly image2D input_image;
layout(r16f, set = 0, binding = 1) uniform restrict writeonly image2D output_image;
layout(r16f, set = 0, binding = 2) uniform image2D depth_image;

// Our push PushConstant
layout(push_constant, std430) uniform Params {
	vec2 image_size;
	vec2 reserved;
} params;

// The code we want to execute in each invocation
void main() {
	ivec2 iuv = ivec2(gl_GlobalInvocationID.xy);

	// Just in case the effect_size size is not divisable by 8
	if ((iuv.x >= params.image_size.x) || (iuv.y >= params.image_size.y)) {
		return;
	}
    
    vec4 color = imageLoad(input_image, iuv);
	imageStore(output_image, iuv, color);
}