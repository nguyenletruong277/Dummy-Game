shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Màu vàng
uniform float line_thickness : hint_range(0.0, 10.0) = 4.0; // Tăng lên 4.0 cho dễ thấy

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    vec4 current_color = texture(TEXTURE, UV);
    
    // Kiểm tra độ trong suốt của các pixel xung quanh
    float alpha = current_color.a;
    alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    
    // Nếu pixel hiện tại trong suốt nhưng pixel bên cạnh có màu -> vẽ đường viền
    if (current_color.a < 0.1 && alpha > 0.1) {
        COLOR = line_color;
    } else {
        COLOR = current_color;
    }
}