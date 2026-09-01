shader_type canvas_item;

uniform vec4 yellow_color : source_color = vec4(1.0, 0.85, 0.1, 1.0);
uniform vec4 blue_color : source_color = vec4(0.15, 0.45, 1.0, 1.0);

uniform float progress : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);

	if (UV.y > 1.0 - progress) {
		COLOR = vec4(yellow_color.rgb, texture_color.a);
	} else {
		COLOR = vec4(blue_color.rgb, texture_color.a);
	}
}