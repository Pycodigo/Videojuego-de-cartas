shader_type canvas_item;

uniform vec4 yellow_color : source_color = vec4(1.0, 0.85, 0.1, 1.0);
uniform vec4 blue_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	float visual_y = 1.0 - UV.y;
	float yellow_amount = 1.0 - progress;

	if (visual_y < yellow_amount) {
		COLOR = yellow_color;
	} else {
		COLOR = blue_color;
	}
}