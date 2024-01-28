shader_type spatial;

render_mode unshaded;

void vertex() {
	// Called for every vertex the material is visible on.
}

uniform float target_r = 0.3;
uniform float thickness = 0.1;
uniform float fade = 0.01;
uniform int slice_count = 3;
uniform float spin_speed = 1.0;
uniform float slice_width1 = 0.4;
uniform float slice_width2 = 2.4;

uniform float circle_r = 0.1;

uniform vec3 color : source_color = vec3(1.0, 0, 0);

void fragment() {
	vec2 uv_plus_minus = UV * 2.0 - vec2(1.0);
	
	float angle = atan(uv_plus_minus.y, uv_plus_minus.x);
	float angle_multiplied = angle * float(slice_count);
	float angle_rotated = mod(angle_multiplied - TIME*spin_speed, PI*2.0);
	float diff_to_pi = abs(PI - angle_rotated);
	float a_slice1 = smoothstep(slice_width1, slice_width1 + fade, diff_to_pi); 
	float a_slice2 = smoothstep(slice_width2, slice_width2 + fade, diff_to_pi);
	
	float rsq = uv_plus_minus.x * uv_plus_minus.x + uv_plus_minus.y * uv_plus_minus.y;
	float r = sqrt(rsq);
	
	float rdiff = abs(target_r - r);
	
	float a_outer1 = 1.0 - smoothstep(target_r + thickness, target_r + thickness + fade, rdiff);
	float a_inner1 = smoothstep(target_r, target_r + fade, rdiff);
	
	float a_outer2 = 1.0 - smoothstep(target_r + thickness + thickness - fade, target_r + thickness + thickness, rdiff);
	float a_inner2 = smoothstep(target_r + thickness, target_r + thickness + fade, rdiff);
	
	float acircle = 1.0 - smoothstep(circle_r, circle_r+fade, r);
	float a1 = min(min(a_inner1, a_outer1), a_slice1);
	float a2 = min(min(a_inner2, a_outer2), a_slice2);

	float a = max(max(acircle, a1), a2);

	ALPHA = a;
	ALBEDO = color;
	
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
