shader_type spatial;
render_mode unshaded;

// Color Land 3D — Tropical Cartoon Ocean Shader
// Chiroyli tropik zangori okean, yumshoq animatsiyali to'lqinlar va oq ko'pik

uniform vec4 deep_color : source_color = vec4(0.01, 0.45, 0.75, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.06, 0.75, 0.88, 1.0);
uniform vec4 foam_color : source_color = vec4(0.95, 0.98, 1.0, 0.9);
uniform float wave_speed : hint_range(0.0, 2.0) = 0.45;
uniform float wave_scale : hint_range(0.01, 0.5) = 0.06;

void fragment() {
	vec2 uv = UV * 16.0;
	float t = TIME * wave_speed;

	// Stylized layered wave pattern
	float w1 = sin(uv.x * 2.5 + t * 1.2) * cos(uv.y * 2.0 + t * 0.8);
	float w2 = sin((uv.x * 1.5 - uv.y * 1.8) + t * 0.9);
	float w3 = cos(uv.x * 3.2 + uv.y * 2.8 - t * 1.4);
	float wave = (w1 * 0.5 + w2 * 0.3 + w3 * 0.2);

	// Blend deep and shallow tropical turquoise ocean
	vec3 water = mix(deep_color.rgb, shallow_color.rgb, 0.55 + 0.45 * wave);

	// Gentle foam crests on wave peaks
	float crest = smoothstep(0.48, 0.82, wave);
	water = mix(water, foam_color.rgb, crest * 0.38);

	ALBEDO = water;
}
