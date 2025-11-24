shader_type canvas_item;

uniform float flow_speed = -1;  // Negative for top-to-bottom flow
uniform float noise_intensity = 0.15; // Brightness of light patches
uniform float noise_scale = 5.0; // Higher value = more frequent, smaller patches
uniform float edge_wiggle_amplitude = 0.03; // How far the sides move in/out (0.03 = 3% of sprite width)
uniform float edge_wiggle_frequency = 5.0; // How fast the edges wiggle

void fragment() {
    vec2 uv = UV;

    // Create animated vertical movement flowing downward
    float time_offset = TIME * flow_speed;

    // Generate sine wave-based noise pattern for light patches
    float noise = sin((uv.y + time_offset) * noise_scale) * 0.5 + 0.5;
    noise = smoothstep(0.6, 0.9, noise) * noise_intensity;

    // ** Edge Wiggle Effect **
    float edge_wave = sin(uv.y * edge_wiggle_frequency + TIME) * edge_wiggle_amplitude;

    // Apply the wave effect only to pixels near the left and right edges
    float edge_mask = smoothstep(0.4, 0.0, uv.x) * smoothstep(0.4, 0.0, 1.0 - uv.x);

    // Offset the UVs based on the edge wave
    uv.x += edge_wave * edge_mask;

    // Sample the original sprite texture with modified UVs
    vec3 flow_color = texture(TEXTURE, uv).rgb + noise;

    // Output final color
    COLOR = vec4(flow_color, texture(TEXTURE, uv).a);
}
