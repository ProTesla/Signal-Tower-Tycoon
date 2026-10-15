// grid.gdshader — draws grid lines on the ground plane.
//
// The trick: instead of building dozens of line meshes, we colour each
// pixel based on how far it is from the nearest tile boundary, measured
// in WORLD coordinates. That way the visual grid always lines up exactly
// with the logical tiles in Grid.gd (both use the same tile size).
shader_type spatial;

uniform vec3 base_color : source_color = vec3(0.13, 0.18, 0.16);
uniform vec3 line_color : source_color = vec3(0.30, 0.55, 0.45);
uniform float tile_size = 2.0;   // must match Grid.TILE_SIZE (set from code)
uniform float line_width = 0.05; // in world units (metres)

varying vec3 world_pos;

void vertex() {
	// Remember where this vertex sits in world space; the fragment shader
	// uses it so the grid pattern is anchored to the world, not the mesh.
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// fract() repeats 0..1 across every tile, so `in_tile` is this pixel's
	// position inside its tile. Distance to the nearest edge on each axis:
	vec2 in_tile = fract(world_pos.xz / tile_size);
	vec2 dist_to_line = min(in_tile, 1.0 - in_tile) * tile_size;
	float dist = min(dist_to_line.x, dist_to_line.y);

	// 1.0 on a grid line, 0.0 elsewhere, with a soft edge to avoid aliasing.
	float line = 1.0 - smoothstep(line_width * 0.5, line_width, dist);

	ALBEDO = mix(base_color, line_color, line);
	ROUGHNESS = 1.0; // matte ground, no specular shine
}
