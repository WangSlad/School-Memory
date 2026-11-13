"""Read-only glTF geometry/material audit; writes a JSON report, never the GLBs.

Run from any directory: python tools/audit_teaching_meshes.py
Only the Python standard library is required. Positions are welded to 1e-5 m
for topology checks; closed overlapping boxes can form non-manifold components.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import re
import struct


ROOT = Path(__file__).resolve().parents[1]


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1],
            a[2] * b[0] - a[0] * b[2],
            a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


class GLB:
    def __init__(self, path):
        self.data = path.read_bytes()
        magic, version, length = struct.unpack_from("<4sII", self.data)
        if magic != b"glTF" or version != 2 or length != len(self.data):
            raise ValueError(f"Invalid glTF 2 GLB: {path}")
        offset = 12
        self.binary = b""
        while offset < length:
            size, kind = struct.unpack_from("<II", self.data, offset)
            chunk = self.data[offset + 8:offset + 8 + size]
            if kind == 0x4E4F534A:
                self.json = json.loads(chunk)
            elif kind == 0x004E4942:
                self.binary = chunk
            offset += 8 + size

    def accessor(self, index):
        a = self.json["accessors"][index]
        if "sparse" in a:
            raise ValueError("Sparse accessors are not supported by this audit")
        view = self.json["bufferViews"][a["bufferView"]]
        if view.get("buffer", 0) != 0:
            raise ValueError("External buffers are not supported")
        fmt = {5120: "b", 5121: "B", 5122: "h", 5123: "H",
               5125: "I", 5126: "f"}[a["componentType"]]
        count = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}[a["type"]]
        stride = view.get("byteStride", struct.calcsize(fmt) * count)
        start = view.get("byteOffset", 0) + a.get("byteOffset", 0)
        return [struct.unpack_from("<" + fmt * count, self.binary, start + i * stride)
                for i in range(a["count"])]


def primitive_audit(glb, primitive):
    if primitive.get("mode", 4) != 4:
        raise ValueError("Only triangle primitives are supported")
    positions = glb.accessor(primitive["attributes"]["POSITION"])
    normals = (glb.accessor(primitive["attributes"]["NORMAL"])
               if "NORMAL" in primitive["attributes"] else None)
    indices = ([x[0] for x in glb.accessor(primitive["indices"])]
               if "indices" in primitive else list(range(len(positions))))
    keys = [tuple(round(x, 5) for x in p) for p in positions]
    edges = Counter()
    triangles = Counter()
    adjacency = defaultdict(set)
    records = []
    mismatch = degenerate = 0
    for i in range(0, len(indices), 3):
        ids = indices[i:i + 3]
        a, b, c = [positions[k] for k in ids]
        face = cross(sub(b, a), sub(c, a))
        area_squared = dot(face, face)
        degenerate += area_squared < 1e-20
        if normals and area_squared >= 1e-20:
            # Compare orientation independently of triangle area.
            mismatch += any(dot(face, normals[k]) < -1e-6 * area_squared ** 0.5 for k in ids)
        vertices = [keys[k] for k in ids]
        triangles[tuple(sorted(vertices))] += 1
        for k, vertex in enumerate(vertices):
            adjacency[vertex].update(vertices)
            edges[tuple(sorted((vertex, vertices[(k + 1) % 3])))] += 1
        records.append((vertices[0], (a, b, c)))

    vertex_component = {}
    components = []
    for first in adjacency:
        if first in vertex_component:
            continue
        component_id = len(components)
        stack = [first]
        vertex_component[first] = component_id
        vertices = []
        while stack:
            vertex = stack.pop()
            vertices.append(vertex)
            for neighbor in adjacency[vertex]:
                if neighbor not in vertex_component:
                    vertex_component[neighbor] = component_id
                    stack.append(neighbor)
        components.append({
            "bounds_min": [min(v[k] for v in vertices) for k in range(3)],
            "bounds_max": [max(v[k] for v in vertices) for k in range(3)],
            "boundary_edges": 0, "nonmanifold_edges": 0,
            "triangle_count": 0, "signed_volume_m3": 0.0,
            "_origin": vertices[0],
        })
    for edge, count in edges.items():
        component = components[vertex_component[edge[0]]]
        component["boundary_edges"] += count == 1
        component["nonmanifold_edges"] += count > 2
    for vertex, points in records:
        component = components[vertex_component[vertex]]
        a, b, c = [sub(p, component["_origin"]) for p in points]
        component["signed_volume_m3"] += dot(a, cross(b, c)) / 6.0
        component["triangle_count"] += 1
    for component in components:
        del component["_origin"]
        volume = component["signed_volume_m3"]
        component["signed_volume_m3"] = round(volume, 9)
        component["closed_by_edge_count"] = component["boundary_edges"] == 0
        component["orientation"] = ("outward" if volume > 1e-9 else
                                    "inward" if volume < -1e-9 else "zero_volume")
    return {
        "attributes": sorted(primitive["attributes"]),
        "material_index": primitive.get("material"),
        "triangle_count": len(indices) // 3,
        "degenerate_triangles": degenerate,
        "triangles_with_opposed_vertex_normals": mismatch,
        "boundary_edges": sum(c == 1 for c in edges.values()),
        "nonmanifold_edges": sum(c > 2 for c in edges.values()),
        "duplicate_triangles_ignoring_winding": sum(c - 1 for c in triangles.values() if c > 1),
        "signed_volume_m3": round(sum(c["signed_volume_m3"] for c in components), 9),
        "components": components,
    }


def model_audit(path):
    glb = GLB(path)
    meshes = []
    for index, mesh in enumerate(glb.json["meshes"]):
        meshes.append({"index": index, "name": mesh.get("name", ""),
                       "primitives": [primitive_audit(glb, p) for p in mesh["primitives"]]})
    primitives = [p for m in meshes for p in m["primitives"]]
    components = [c for p in primitives for c in p["components"]]
    materials = []
    for index, material in enumerate(glb.json.get("materials", [])):
        factor = material.get("pbrMetallicRoughness", {}).get("baseColorFactor", [1, 1, 1, 1])
        materials.append({"index": index, "name": material.get("name", ""),
                          "alpha_mode": material.get("alphaMode", "OPAQUE"),
                          "base_color_factor": factor,
                          "double_sided": material.get("doubleSided", False)})
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": hashlib.sha256(glb.data).hexdigest(),
        "summary": {
            "meshes": len(meshes), "nodes": len(glb.json["nodes"]),
            "components": len(components),
            "closed_components": sum(c["closed_by_edge_count"] for c in components),
            "outward_components": sum(c["orientation"] == "outward" for c in components),
            "inward_components": sum(c["orientation"] == "inward" for c in components),
            "meshes_positive_volume": sum(sum(p["signed_volume_m3"] for p in m["primitives"]) > 1e-9 for m in meshes),
            "meshes_negative_volume": sum(sum(p["signed_volume_m3"] for p in m["primitives"]) < -1e-9 for m in meshes),
            "boundary_edges": sum(p["boundary_edges"] for p in primitives),
            "triangles_with_opposed_vertex_normals": sum(p["triangles_with_opposed_vertex_normals"] for p in primitives),
            "degenerate_triangles": sum(p["degenerate_triangles"] for p in primitives),
            "meshes_with_uv": sum(any("TEXCOORD_0" in p["attributes"] for p in m["primitives"]) for m in meshes),
        },
        "materials": materials, "meshes": meshes,
    }


def material_overrides():
    result = []
    directory = ROOT / "assets/buildings/teaching_floor/spring/materials"
    for path in sorted(directory.glob("*.tres")):
        text = path.read_text(encoding="utf-8-sig")
        entry = {"path": path.relative_to(ROOT).as_posix()}
        for key in ["resource_name", "transparency", "cull_mode", "albedo_color",
                    "depth_draw_mode", "alpha_hash_scale", "alpha_scissor_threshold"]:
            match = re.search(r"^" + key + r"\s*=\s*(.+)$", text, re.MULTILINE)
            if match:
                entry[key] = match.group(1).strip()
        result.append(entry)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/teaching_spring_review/mesh_audit.json")
    args = parser.parse_args()
    models = [model_audit(ROOT / f"assets/buildings/{name}/{name}.glb")
              for name in ["teaching_floor", "teaching_five_floor"]]
    report = {
        "method": {
            "position_weld_precision_m": 0.00001,
            "closed_definition": "No edge used by exactly one triangle after position welding; this does not imply a manifold union of overlapping solids.",
            "orientation": "Signed volume of closed geometry in GLB right-handed coordinates; positive outward, negative inward. NORMAL agreement is checked separately.",
            "bounds": "Mesh-local GLB coordinates (metres), before node transforms.",
            "read_only": "GLBs are read only; only this JSON report is written.",
        },
        "models": models,
        "godot_material_resource_properties": material_overrides(),
        "findings": [
            "The single-storey source exports inward box winding; its original double-sided materials mask this.",
            "The five-storey generator reverses source polygons and produces outward geometry without boundary edges; do not reverse that GLB again.",
            "Original Window glazing is OPAQUE; original balustrade glass is BLEND with alpha 0.25. Making both roles alpha-blended reveals the unfinished interior shell.",
            "Many separated glass panes are merged into one mesh per floor; alpha blending such a mesh cannot reliably order individual panes or both sides of every closed pane.",
            "Duplicate wall triangles occur at adjoining box end caps. Their presence is distinct from an open or missing face.",
        ],
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    for model in models:
        print(model["path"], json.dumps(model["summary"], ensure_ascii=True))
    print(f"AUDIT_WRITTEN {args.output}")


if __name__ == "__main__":
    main()
