shader_type canvas_item;

uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.08;
uniform float flicker_speed : hint_range(0.0, 10.0) = 3.0;
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.015;
uniform float time_val : hint_range(0.0, 1000.0) = 0.0;

// Barrel/spherical distortion
vec2 distort(vec2 uv) {
	vec2 cc = uv - 0.5;
	float dist = dot(cc, cc) * distortion_strength;
	return uv + cc * dist;
}

void fragment() {
	vec2 uv = distort(UV);

	// Discard pixels outside [0,1] after distortion (creates curved screen edge)
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
		return;
	}

	// Scanlines
	float scanline = sin(uv.y * SCREEN_PIXEL_SIZE.y * 3.14159 * 720.0) * 0.5 + 0.5;
	float scan_factor = 1.0 - scanline * scanline_intensity;

	// Phosphorus flicker
	float flicker = 1.0 - sin(time_val * flicker_speed) * 0.012;

	// Vignette
	vec2 vig_uv = uv * (1.0 - uv.yx);
	float vignette = pow(vig_uv.x * vig_uv.y * 15.0, 0.25);
	vignette = clamp(vignette, 0.0, 1.0);

	COLOR = vec4(0.0, 0.0, 0.0, scanline_intensity * scan_factor * (1.0 - vignette) * 0.5 * flicker);
}
