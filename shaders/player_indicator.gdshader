shader_type spatial;

render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform float target_r = 0.4;
uniform float thickness = 0.1;
uniform float fade = 0.01;
uniform int slice_count = 3;
uniform float spin_speed = 1.0;
uniform float slice_width = 0.4;

uniform vec3 color : source_color = vec3(1.0, 0, 0);

void fragment() {
	vec2 uv_plus_minus = UV * 2.0 - vec2(1.0);
	
	float angle = atan(uv_plus_minus.y, uv_plus_minus.x);
	float angle_multiplied = angle * float(slice_count);
	float angle_rotated = mod(angle_multiplied - TIME*spin_speed, PI*2.0);
	float diff_to_pi = abs(PI - angle_rotated);
	float a_slice = smoothstep(slice_width, slice_width + fade, diff_to_pi); 
	
	float rsq = uv_plus_minus.x * uv_plus_minus.x + uv_plus_minus.y * uv_plus_minus.y;
	float r = sqrt(rsq);
	
	float rdiff = abs(target_r - r);
	
	float a_outer = 1.0 - smoothstep(target_r + thickness, target_r + thickness + fade, rdiff);
	float a_inner = smoothstep(target_r, target_r + fade, rdiff);
	float a = min(min(a_inner, a_outer), a_slice);

	ALPHA = a;
	ALBEDO = color;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
