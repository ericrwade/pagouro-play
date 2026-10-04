shader_type canvas_item;
// A jigsaw piece: the picture, cut by its baked edge mask (see piece_masks.gd). The cut line is drawn here too, as a
// soft ink rim just inside the edge, read from a blurrier mip of the same mask, so it stays smooth at every zoom
// (a Line2D outline stair-steps in GL Compatibility).
uniform sampler2D mask : filter_linear_mipmap, repeat_disable;
uniform vec4 rect;       // the mask's area in picture pixels: x, y, width, height
uniform vec2 tex_size;   // the picture's size in pixels
uniform float rim = 0.6;          // strength of the ink cut line; fades to 0 when the puzzle is finished
uniform float solid = 0.0;        // 1 = ignore the soft edge, so a finished picture shows no hairline seams
uniform vec3 ink : source_color = vec3(0.2, 0.157, 0.133);  // D-74 warm black

void fragment() {
	vec2 m = (UV * tex_size - rect.xy) / rect.zw;
	float a = texture(mask, m).r;
	float blur = texture(mask, m, 1.4).r;  // about two screen pixels of falloff at any zoom
	float line = clamp((1.0 - blur) * 2.5, 0.0, 1.0);  // strongest at the edge, gone a pixel or two in
	COLOR.rgb = mix(COLOR.rgb, ink, rim * line);
	// fully opaque from the true edge inward and soft just outside it, so two joined pieces close their seam
	// instead of each going half-clear over the table
	COLOR.a *= mix(smoothstep(0.0, 0.5, a), 1.0, solid);
}
