shader_type spatial;
render_mode cull_back, diffuse_burley, specular_disabled;

// Soft cloud ocean colors
uniform vec4 cloud_base_color : source_color = vec4(0.78, 0.88, 0.98, 1.0);
uniform vec4 cloud_highlight_color : source_color = vec4(1.0, 0.98, 0.94, 1.0);
uniform vec4 cloud_shadow_color : source_color = vec4(0.45, 0.62, 0.82, 1.0);

uniform float drift_speed : hint_range(0.01, 1.0) = 0.08;
uniform float wave_amplitude : hint_range(0.5, 8.0) = 3.5;


// Procedural noise approximation for soft billowy clouds
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float val = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		val += amp * noise(p);
		p *= 2.05;
		amp *= 0.5;
	}
	return val;
}


void vertex() {
	vec2 uv_drift = (VERTEX.xz * 0.012) + vec2(TIME * drift_speed * 0.6, TIME * drift_speed * 0.4);
	float billow = fbm(uv_drift);
	// Displace vertex for billowy 3D cloud peaks
	VERTEX.y += (billow * 2.0 - 1.0) * wave_amplitude;
}


void fragment() {
	vec2 uv_drift = (VERTEX.xz * 0.015) + vec2(TIME * drift_speed, TIME * drift_speed * 0.7);
	float billow = fbm(uv_drift);

	// Light cloud peaks vs shadowed valleys
	vec3 col = mix(cloud_shadow_color.rgb, cloud_base_color.rgb, smoothstep(0.2, 0.6, billow));
	col = mix(col, cloud_highlight_color.rgb, smoothstep(0.65, 0.9, billow));

	ALBEDO = col;
	ROUGHNESS = 0.95;
	METALLIC = 0.0;
}

