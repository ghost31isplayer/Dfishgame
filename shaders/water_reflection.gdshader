shader_type canvas_item;

@export_range(0.0, 1.0)
uniform float level = 0.5;

@export_color
uniform vec4 water_albedo = vec4(0.26, 0.23, 0.73, 1.0);

@export_range(0.0, 1.0)
uniform float water_opacity = 0.35;

uniform float water_speed = 0.05;
uniform float wave_distortion = 0.2;

@export_range(1, 20)
uniform int wave_multiplyer = 7;

uniform bool water_texture_on = true;
uniform float reflection_X_offset = 0.0;
uniform float reflection_Y_offset = 0.0;

@export_texture
uniform sampler2D noise_texture;

@export_texture
uniform sampler2D noise_texture2;

void fragment() {
	vec2 uv = UV;
	COLOR = vec4(0.0);
	
	if (uv.y >= level) {
		COLOR.a = 1.0;

		// distorted reflections
		vec2 water_uv = vec2(uv.x, uv.y * float(wave_multiplyer));
		float noise = texture(noise_texture, vec2(water_uv.x + TIME * water_speed, water_uv.y)).x * wave_distortion;
		noise -= (0.5 * wave_distortion);
		
		// water texture
		if (water_texture_on) {
			float water_texture_limit = 0.35;
			vec4 water_texture = texture(noise_texture2, uv * vec2(0.5, 4.0) + vec2(noise, 0.0));
			float water_texture_value = (water_texture.x < water_texture_limit) ? 1.0 : 0.0;	
			COLOR.rgb = vec3(water_texture_value);
		}
	
		// combine with screen texture and water color
		vec4 current_texture = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x + noise + reflection_X_offset, 1.0 - SCREEN_UV.y - (level - 0.5) * 2.0 + reflection_Y_offset));
		COLOR = mix(COLOR, current_texture, 0.5);
		COLOR = mix(COLOR, water_albedo, water_opacity);
	}
}
