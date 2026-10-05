shader_type canvas_item;

uniform vec4 green_color : source_color = vec4(0.0, 1.0, 0.0, 1.0);
uniform vec4 yellow_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform vec4 orange_color : source_color = vec4(1.0, 0.5, 0.0, 1.0);
uniform vec4 dark_orange_color : source_color = vec4(0.8, 0.25, 0.0, 1.0);
uniform vec4 red_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float segment_index = 0.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	float segment_size = 1.0 / 5.0;
	float segment_limit = 1.0 - ((segment_index + 1.0) / 5.0);

	// Cuánto está lleno este segmento.
	float segment_progress = (progress - segment_limit) / segment_size;
	segment_progress = clamp(segment_progress, 0.0, 1.0);

	vec4 energy_color;

	if (progress >= 0.80) {
		energy_color = green_color;
	}
	else if (progress >= 0.60) {
		energy_color = yellow_color;
	}
	else if (progress >= 0.40) {
		energy_color = orange_color;
	}
	else if (progress >= 0.20) {
		energy_color = dark_orange_color;
	}
	else {
		energy_color = red_color;
	}

	if (UV.y > 1.0 - segment_progress) {
		COLOR = vec4(energy_color.rgb, texture_color.a);
	}
	else {
		COLOR = vec4(0.0, 0.0, 0.0, texture_color.a);
	}
}