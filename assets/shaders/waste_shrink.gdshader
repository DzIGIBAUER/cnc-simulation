shader_type spatial;

uniform vec3 tool_position;
uniform vec3 retreat_position;

void vertex() {
	if (VERTEX.y > retreat_position.y) {
		VERTEX.y = max(min(VERTEX.y, tool_position.y), retreat_position.y);
	};
}
