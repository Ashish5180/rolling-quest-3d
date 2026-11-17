shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 deep_color : source_color = vec4(0.04, 0.22, 0.48, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.08, 0.68, 0.85, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);

uniform float wave_speed : hint_range(0.1, 4.0) = 1.4;
uniform float wave_height : hint_range(0.1, 3.0) = 0.9;
uniform float wave_freq : hint_range(0.01, 0.5) = 0.07;


void vertex() {
	// Dual-frequency overlapping rolling swells
	float w1 = sin(VERTEX.x * wave_freq + TIME * wave_speed);
	float w2 = cos(VERTEX.z * wave_freq * 1.3 + TIME * wave_speed * 0.8);
	float w3 = sin((VERTEX.x + VERTEX.z) * wave_freq * 0.7 + TIME * wave_speed * 1.1);
	VERTEX.y += (w1 * 0.5 + w2 * 0.35 + w3 * 0.3) * wave_height;
}


void fragment() {
	float w1 = sin(VERTEX.x * wave_freq + TIME * wave_speed);
	float w2 = cos(VERTEX.z * wave_freq * 1.3 + TIME * wave_speed * 0.8);
	float wave_val = (w1 + w2) * 0.5;

	// Gradient from deep ocean to tropical shallow
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, clamp(wave_val * 0.5 + 0.5, 0.0, 1.0));

	// White foam on top of rolling wave peaks
	if (wave_val > 0.65) {
		float foam_factor = smoothstep(0.65, 0.95, wave_val);
		water = mix(water, foam_color.rgb, foam_factor * 0.85);
	}

	ALBEDO = water;
	ROUGHNESS = 0.18;
	METALLIC = 0.05;
	SPECULAR = 0.8;
}

