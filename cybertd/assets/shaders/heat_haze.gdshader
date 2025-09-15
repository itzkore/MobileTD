shader_type canvas_item;

uniform float shake_amount = 0.0;
uniform float speed = 5.0;

void fragment() {
	vec2 uv = UV;
	uv.x += sin(uv.y * 10.0 + TIME * speed) * shake_amount;
	uv.y += cos(uv.x * 10.0 + TIME * speed) * shake_amount;
	COLOR = texture(TEXTURE, uv);
}
