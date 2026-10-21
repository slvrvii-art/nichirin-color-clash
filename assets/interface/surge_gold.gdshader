shader_type canvas_item;

// Gold metallic gradient for the SURGE wordmark on cards.
// Fill glyphs (white font colour) receive the gradient; the dark outline pass is kept.
uniform float height = 20.0;
varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	float t = clamp((local_pos.y - height * 0.16) / (height * 0.70), 0.0, 1.0);
	vec3 c1 = vec3(1.00, 0.97, 0.80);
	vec3 c2 = vec3(0.98, 0.80, 0.38);
	vec3 c3 = vec3(0.60, 0.40, 0.12);
	vec3 c4 = vec3(1.00, 0.90, 0.58);
	vec3 c5 = vec3(0.70, 0.47, 0.16);
	vec3 g;
	if (t < 0.40) g = mix(c1, c2, t / 0.40);
	else if (t < 0.52) g = mix(c2, c3, (t - 0.40) / 0.12);
	else if (t < 0.66) g = mix(c3, c4, (t - 0.52) / 0.14);
	else g = mix(c4, c5, (t - 0.66) / 0.34);
	float fill = step(1.2, COLOR.r + COLOR.g + COLOR.b);
	COLOR = vec4(mix(COLOR.rgb, g, fill), COLOR.a);
}
