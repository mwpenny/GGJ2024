shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float wall_min_height = 3.0;
uniform vec4 base_color : source_color = vec4(0, 0.15, 0.2, 0.45);

varying vec3 model_pos;
void vertex() {
	model_pos = (MODEL_MATRIX  * vec4(VERTEX.xyz, 0)).xyz;
	//NORMAL = vec3(0,0,0);
}

uniform int angular_period_a = 1;
uniform float speed_a = 1.0;
uniform int angular_period_b = 1;
uniform float speed_b = 1.0;
uniform float height_boost_strength = 1.0;

void fragment()
{
	float angle = atan(model_pos.x, model_pos.z);
	
	float angular_modified_a = abs(PI - mod(angle + speed_a*TIME, PI*2.0));
	float angular_modified_b = abs(PI - mod(angle + speed_b*TIME, PI*2.0));
	float angular = max(angular_modified_a, angular_modified_b);
	
	float height_boost = angular * height_boost_strength;
	float wall_height = wall_min_height + height_boost;
	
	ALPHA = base_color.a * (1.0 - (model_pos.y / wall_height));
	//ALPHA = clamp(wall_max_height - world_pos.y, 0, 1) * alpha_boost;
	ALBEDO = base_color.rgb;
}