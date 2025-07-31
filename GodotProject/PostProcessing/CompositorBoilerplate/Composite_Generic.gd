#
# By Chris Johnson
#
# Resources that made any of this nonsense possible:
# https://github.com/pink-arcana/godot-distance-field-outlines/discussions/1
#
# the creator who uploaded the first video linked in the "getting started"
# section of the above link gave me their source code, which was nice.
# https://gist.github.com/GustJc/513d1834cb13b1e42058c3fcfa4a81f6
#
# Where I got info on how to use p_render_data.get_render_scene_data()
# https://github.com/godotengine/godot/pull/80214#issuecomment-1953258434
# https://github.com/godotengine/godot/blob/master/servers/rendering/renderer_rd/shaders/scene_data_inc.glsl
#
# This page has a solution for the TEXTURE_USAGE_STORAGE_BIT error if that's
# causing trouble.
# https://forum.godotengine.org/t/problem-with-compositor-shader-texture-loading/78130/2

@tool
extends CompositorEffect
class_name PostProcessGeneric

## the push constant will always contain a screen size vector2 and a blank vector2.
## extended_push_constant will be added onto the end of that push constant.
## set this value from inheriting class before calling Super() in _render_callback()
var extended_push_constant : PackedFloat32Array = []

@export var shader_file : Resource: # = preload("res://Assets/PostProcessing/Water/Composite_Underwater_Perlin.glsl"):
	get:
		return shader_file
	set(newValue):
		shader_file = newValue
		_reload_source()
		shader_file.changed.connect(Callable(self, "_reload_source"))

## when enabled, the back buffer will always be set 0, binding 1.
@export var NeedsBackBuffer : bool = false:
	get:
		return NeedsBackBuffer
	set(newValue):
		NeedsBackBuffer = newValue
		_reload_source()

## when enabled, depth buffer will be in set 0 at either binding 1 or 2, depending
## on if NeedsBackBuffer is enabled.
@export var NeedsDepthBuffer : bool = false:
	get:
		return NeedsDepthBuffer
	set(newValue):
		NeedsDepthBuffer = newValue
		_reload_source()

var backbuffer_source : Resource = preload("res://Assets/PostProcessing/CompositorBoilerplate/CloneBuffer.glsl")
var backbuffer_context : StringName = "PostProcess"
var backbuffer_name : StringName = "Backbuffer"

var rd: RenderingDevice
var shader: RID
var pipeline: RID
var pipeline_copy: RID

var _initialized : bool = false

func _initialize() -> void:
	# can't use _init() because it runs before @export values populate.
	
	effect_callback_type = EFFECT_CALLBACK_TYPE_POST_TRANSPARENT
	rd = RenderingServer.get_rendering_device()
	RenderingServer.call_on_render_thread(_initialize_compute)
	#shader_file.changed.connect(Callable(self, "_reload_source"))
	
	_initialized = true

func _reload_source():
	if not _initialized: return
	_clean()
	RenderingServer.call_on_render_thread(_initialize_compute)

func _clean():
	print("DESTROYING SHADER!")
	if shader.is_valid():
		# Freeing our shader will also free any dependents such as the pipeline!
		rd.free_rid(shader)

# System notifications, we want to react on the notification that
# alerts us we are about to be destroyed.
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		# can't just call _clean here because the function will already be deleted somehow.
		if shader.is_valid():
			rd.free_rid(shader)


#region Code in this region runs on the rendering thread.
# Compile our shader at initialization.
func _initialize_compute() -> void:
	rd = RenderingServer.get_rendering_device()
	if not rd:
		return
	
	#access_resolved_depth = NeedsDepthBuffer
	
	# Compile backbuffer shader.
	if NeedsBackBuffer:
		var bb_shader_file = backbuffer_source
		var bb_shader_spirv: RDShaderSPIRV = bb_shader_file.get_spirv()
		var shader_copy := rd.shader_create_from_spirv(bb_shader_spirv)
		if shader_copy.is_valid():
			pipeline_copy = rd.compute_pipeline_create(shader_copy)
	
	# Compile our shader.
	var shader_spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(shader_spirv)
	if shader.is_valid():
		pipeline = rd.compute_pipeline_create(shader)


# Called by the rendering thread every frame.
func _render_callback(_p_effect_callback_type: EffectCallbackType, p_render_data: RenderData) -> void:
	if not shader_file: return
	if not _initialized:
		_initialize()
		return
	
	if not (rd and pipeline.is_valid()): # and p_effect_callback_type == EFFECT_CALLBACK_TYPE_POST_TRANSPARENT:
		return
	
	# Get our render scene buffers object, this gives us access to our render buffers.
	# Note that implementation differs per renderer hence the need for the cast.
	var render_scene_buffers : RenderSceneBuffersRD = p_render_data.get_render_scene_buffers()
	var render_scene_data := p_render_data.get_render_scene_data()
	if not (render_scene_buffers and render_scene_data):
		return
	
	# Get our render size, this is the 3D render resolution!
	var size: Vector2i = render_scene_buffers.get_internal_size()
	if size.x == 0 and size.y == 0:
		return

	# We can use a compute shader here.
	@warning_ignore("integer_division")
	var x_groups := (size.x - 1) / 8 + 1
	@warning_ignore("integer_division")
	var y_groups := (size.y - 1) / 8 + 1
	var z_groups := 1

	# Create push constant.
	# Must be aligned to 16 bytes and be in the same order as defined in the shader.
	var push_constant_copy := PackedFloat32Array([
		size.x,
		size.y,
		0.0,
		0.0
	])
	var push_constant := PackedFloat32Array([
		size.x,
		size.y,
		0.0,
		0.0,
	])
	push_constant.append_array(extended_push_constant)
	var valuesOver = (push_constant.size() % 4)
	var valuesToAdd = 4 - valuesOver
	#push_constant.resize(push_constant.size() + valuesToAdd)
	if valuesOver > 0:
		for i in valuesToAdd:
			push_constant.append(0.0)
	
	# backbuffer
	if NeedsBackBuffer and \
	!render_scene_buffers.has_texture(backbuffer_context, backbuffer_name):
		var render_size : Vector2 = render_scene_buffers.get_internal_size()
		var effect_size : Vector2 = render_size
		var usage_bits : int = RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT\
			| RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
		
		render_scene_buffers.create_texture(
			backbuffer_context,
			backbuffer_name,
			RenderingDevice.DATA_FORMAT_R16G16B16A16_SNORM,
			usage_bits,
			RenderingDevice.TEXTURE_SAMPLES_1,
			effect_size,
			1, 1, true, true
		)

	# Loop through views just in case we're doing stereo rendering.
	# No extra cost if this is mono.
	var view_count: int = render_scene_buffers.get_view_count()
	for view in view_count:
		# Get the RID for our color image, we will be reading from and
		# writing to it.
		var input_image: RID = render_scene_buffers.get_color_layer(view)
		
		var depth_image: RID
		if NeedsDepthBuffer:
			depth_image = render_scene_buffers.get_depth_layer(view)
		
		var backbuffer_image: RID
		if NeedsBackBuffer:
			backbuffer_image = render_scene_buffers.get_texture_slice(
				backbuffer_context, backbuffer_name, view, 0, 1, 1
			)
		
		# Create a uniform set, this will be cached, the cache will be
		# cleared if our viewports configuration is changed.
		var setContentArray = []
		
		# frame buffer
		var uniform := RDUniform.new()
		uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		uniform.binding = 0
		uniform.add_id(input_image)
		setContentArray.insert(0, uniform)
		
		#backbuffer
		if NeedsBackBuffer:
			var uniform_backbuffer := RDUniform.new()
			uniform_backbuffer.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
			uniform_backbuffer.binding = setContentArray.size() #1
			uniform_backbuffer.add_id(backbuffer_image)
			setContentArray.insert(0, uniform_backbuffer)
		
		#depth
		if NeedsDepthBuffer:
			var uniform_depth := RDUniform.new()
			uniform_depth.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
			uniform_depth.binding = setContentArray.size() #2
			uniform_depth.add_id(depth_image)
			setContentArray.insert(0, uniform_depth)
		
		var uniform_set := UniformSetCacheRD.get_cache(
			shader, 0, setContentArray
		)
		
		# scene data uniform
		var scene_data_buffer : RID = render_scene_data.get_uniform_buffer()
		var uniform_scene_data := RDUniform.new()
		uniform_scene_data.uniform_type = RenderingDevice.UNIFORM_TYPE_UNIFORM_BUFFER
		uniform_scene_data.binding = 0
		uniform_scene_data.add_id(scene_data_buffer)
		
		var uniform_set_data_buffer := UniformSetCacheRD.get_cache(
			shader, 1, [uniform_scene_data]
		)
		
		var compute_list
		
		# copy screen tex to backbuffer
		if NeedsBackBuffer:
			compute_list = rd.compute_list_begin()
			rd.compute_list_bind_compute_pipeline(compute_list, pipeline_copy)
			rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
			rd.compute_list_set_push_constant(compute_list,
				push_constant_copy.to_byte_array(),
				push_constant_copy.size() * 4
			)
			rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
			rd.compute_list_end()
		
		# Run our compute shader.
		compute_list = rd.compute_list_begin()
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
		rd.compute_list_bind_uniform_set(compute_list, uniform_set_data_buffer, 1)
		rd.compute_list_set_push_constant(compute_list,
			push_constant.to_byte_array(),
			push_constant.size() * 4
		)
		rd.compute_list_dispatch(compute_list, x_groups, y_groups, z_groups)
		rd.compute_list_end()
#endregion
