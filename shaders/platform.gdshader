shader_type spatial;

render_mode world_vertex_coords;

varying vec3 local_vx;
void vertex() {
	local_vx = VERTEX;
	// Called for every vertex the material is visible on.
}

uniform float fade_width = 2.0;
uniform float inner_end = 6.0;
uniform float mid_begin = 10.0;
uniform float mid_width = 4.0;
uniform float outer_begin = 20.0;

uniform vec3 base_color: source_color;
uniform vec3 inner_color: source_color;
uniform vec3 mid_color: source_color;
uniform vec3 outer_color: source_color;
void fragment() {
	// Called for every pixel the material is visible on.
	vec2 xz = local_vx.xz;
	float r = length(xz);
	
	float mult_inner = 1.0 - smoothstep(inner_end, inner_end + fade_width, r);
	float mult_mid_a = smoothstep(mid_begin, mid_begin+fade_width, r);
	float mult_mid_b = 1.0 - smoothstep(mid_begin + mid_width, mid_begin + mid_width + fade_width, r);
	float mult_mid = min(mult_mid_a, mult_mid_b);
	float mult_outer = smoothstep(outer_begin, outer_begin+fade_width, r);
	
	float total_mult = min(1.0, mult_inner + mult_mid + mult_outer);
	float base_mult = 1.0 - total_mult;
	
	ALBEDO = base_mult * base_color + mult_inner * inner_color + mult_mid * mid_color + mult_outer * outer_color;
}