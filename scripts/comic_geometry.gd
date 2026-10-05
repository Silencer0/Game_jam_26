extends RefCounted
## Small chamfered meshes give light actual bevels to catch, without modifiers.

static func bevel_box(dimensions: Vector3, bevel: float = 0.035) -> ArrayMesh:
	var h: Vector3 = dimensions * 0.5
	var b: float = minf(bevel, minf(h.x, minf(h.y, h.z)) * 0.45)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for side in [-1.0, 1.0]:
			var normal := Vector3.ZERO
			normal[axis] = side
			var points: Array[Vector3] = []
			for corner in [Vector2(-1,-1), Vector2(1,-1), Vector2(1,1), Vector2(-1,1)]:
				var p := Vector3.ZERO
				p[axis] = h[axis] * side
				p[u] = (h[u] - b) * corner.x
				p[v] = (h[v] - b) * corner.y
				points.append(p)
			face(tool, points, normal)
	for axis in range(3):
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for su in [-1.0, 1.0]:
			for sv in [-1.0, 1.0]:
				var points: Array[Vector3] = []
				for end in [-1.0, 1.0]:
					for edge in [0, 1]:
						var p := Vector3.ZERO
						p[axis] = (h[axis] - b) * end
						p[u] = (h[u] - (b if edge == 1 else 0.0)) * su
						p[v] = (h[v] - (b if edge == 0 else 0.0)) * sv
						points.append(p)
				var ordered: Array[Vector3] = [points[0], points[1], points[3], points[2]]
				var normal := Vector3.ZERO
				normal[u] = su
				normal[v] = sv
				face(tool, ordered, normal.normalized())
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var points: Array[Vector3] = []
				for axis in range(3):
					var p := Vector3((h.x-b)*sx, (h.y-b)*sy, (h.z-b)*sz)
					p[axis] += b * [sx, sy, sz][axis]
					points.append(p)
				face(tool, points, Vector3(sx, sy, sz).normalized())
	return tool.commit()

static func face(tool: SurfaceTool, points: Array[Vector3], normal: Vector3) -> void:
	# Godot uses clockwise front faces.
	if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal) > 0.0:
		points.reverse()
	for index in range(1, points.size()-1):
		for p in [points[0], points[index], points[index+1]]:
			tool.set_normal(normal)
			tool.add_vertex(p)
