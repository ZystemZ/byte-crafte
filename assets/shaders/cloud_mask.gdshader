shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;

uniform sampler2D cloud_texture : source_color, filter_linear, repeat_enable;
uniform vec4 cloud_tint : source_color = vec4(0.97, 0.99, 1.0, 0.62);
uniform vec2 drift = vec2(0.0012, 0.0008);
uniform float cloud_scale = 0.75;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.34;

void fragment() {
	vec2 uv = UV * cloud_scale + TIME * drift;
	vec4 mask_sample = texture(cloud_texture, uv);
	float luminance = dot(mask_sample.rgb, vec3(0.299, 0.587, 0.114));
	float cloud_mask = luminance * mask_sample.a;
	cloud_mask = smoothstep(0.08, 0.92, cloud_mask);
	float sky_band = 1.0 - smoothstep(0.50, 0.64, UV.y);
	ALBEDO = cloud_tint.rgb;
	ALPHA = cloud_mask * cloud_tint.a * cloud_opacity * sky_band;
}
