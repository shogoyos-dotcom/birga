using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — Procedural Low-Poly 3D City Mesh Builder.
    /// Recreates the approved cartoon low-poly city models (Small, Medium, Large)
    /// using single-mesh procedural geometry with vertex colors for 60+ FPS mobile performance.
    /// </summary>
    public static class CityMeshBuilder
    {
        private class MeshBuilderContext
        {
            public readonly List<Vector3> Vertices = new List<Vector3>();
            public readonly List<Vector3> Normals = new List<Vector3>();
            public readonly List<Color32> Colors = new List<Color32>();
            public readonly List<Vector2> UVs = new List<Vector2>();
            public readonly List<int> Triangles = new List<int>();

            public void AddQuad(Vector3 a, Vector3 b, Vector3 c, Vector3 d, Vector3 norm, Color32 col)
            {
                int baseIdx = Vertices.Count;
                Vertices.Add(a);
                Vertices.Add(b);
                Vertices.Add(c);
                Vertices.Add(d);

                Normals.Add(norm);
                Normals.Add(norm);
                Normals.Add(norm);
                Normals.Add(norm);

                Colors.Add(col);
                Colors.Add(col);
                Colors.Add(col);
                Colors.Add(col);

                UVs.Add(new Vector2(0, 0));
                UVs.Add(new Vector2(1, 0));
                UVs.Add(new Vector2(1, 1));
                UVs.Add(new Vector2(0, 1));

                Triangles.Add(baseIdx);
                Triangles.Add(baseIdx + 1);
                Triangles.Add(baseIdx + 2);

                Triangles.Add(baseIdx);
                Triangles.Add(baseIdx + 2);
                Triangles.Add(baseIdx + 3);
            }

            public void AddTriangle(Vector3 a, Vector3 b, Vector3 c, Vector3 norm, Color32 col)
            {
                int baseIdx = Vertices.Count;
                Vertices.Add(a);
                Vertices.Add(b);
                Vertices.Add(c);

                Normals.Add(norm);
                Normals.Add(norm);
                Normals.Add(norm);

                Colors.Add(col);
                Colors.Add(col);
                Colors.Add(col);

                UVs.Add(Vector2.zero);
                UVs.Add(Vector2.zero);
                UVs.Add(Vector2.zero);

                Triangles.Add(baseIdx);
                Triangles.Add(baseIdx + 1);
                Triangles.Add(baseIdx + 2);
            }

            public Mesh ToMesh(string name)
            {
                var mesh = new Mesh
                {
                    name = name
                };
                mesh.SetVertices(Vertices);
                mesh.SetNormals(Normals);
                mesh.SetColors(Colors);
                mesh.SetUVs(0, UVs);
                mesh.SetTriangles(Triangles, 0);
                mesh.RecalculateBounds();
                return mesh;
            }
        }

        private static Color32 Lighten(Color32 c, float factor)
        {
            return new Color32(
                (byte)Mathf.Clamp(c.r + 255 * factor, 0, 255),
                (byte)Mathf.Clamp(c.g + 255 * factor, 0, 255),
                (byte)Mathf.Clamp(c.b + 255 * factor, 0, 255),
                c.a);
        }

        private static Color32 Darken(Color32 c, float factor)
        {
            return new Color32(
                (byte)Mathf.Clamp(c.r * (1.0f - factor), 0, 255),
                (byte)Mathf.Clamp(c.g * (1.0f - factor), 0, 255),
                (byte)Mathf.Clamp(c.b * (1.0f - factor), 0, 255),
                c.a);
        }

        private static void AddBox(MeshBuilderContext ctx, Vector3 center, Vector3 size, Color32 col)
        {
            float hx = size.x * 0.5f;
            float hy = size.y * 0.5f;
            float hz = size.z * 0.5f;

            Vector3 p0 = center + new Vector3(-hx, -hy, -hz);
            Vector3 p1 = center + new Vector3( hx, -hy, -hz);
            Vector3 p2 = center + new Vector3( hx,  hy, -hz);
            Vector3 p3 = center + new Vector3(-hx,  hy, -hz);
            Vector3 p4 = center + new Vector3(-hx, -hy,  hz);
            Vector3 p5 = center + new Vector3( hx, -hy,  hz);
            Vector3 p6 = center + new Vector3( hx,  hy,  hz);
            Vector3 p7 = center + new Vector3(-hx,  hy,  hz);

            // Top
            ctx.AddQuad(p3, p2, p6, p7, Vector3.up, Lighten(col, 0.08f));
            // Bottom
            ctx.AddQuad(p4, p5, p1, p0, Vector3.down, Darken(col, 0.25f));
            // Front (+Z)
            ctx.AddQuad(p4, p7, p6, p5, Vector3.forward, col);
            // Back (-Z)
            ctx.AddQuad(p1, p2, p3, p0, Vector3.back, Darken(col, 0.12f));
            // Left (-X)
            ctx.AddQuad(p0, p3, p7, p4, Vector3.left, Darken(col, 0.08f));
            // Right (+X)
            ctx.AddQuad(p5, p6, p2, p1, Vector3.right, Lighten(col, 0.04f));
        }

        private static void AddCylinder(MeshBuilderContext ctx, Vector3 center, float rBot, float rTop, float h, int segs, Color32 col)
        {
            float halfH = h * 0.5f;
            float yBot = center.y - halfH;
            float yTop = center.y + halfH;
            float step = Mathf.PI * 2.0f / segs;

            for (int i = 0; i < segs; i++)
            {
                float a0 = i * step;
                float a1 = (i + 1) * step;

                float c0 = Mathf.Cos(a0), s0 = Mathf.Sin(a0);
                float c1 = Mathf.Cos(a1), s1 = Mathf.Sin(a1);

                Vector3 vb0 = new Vector3(center.x + c0 * rBot, yBot, center.z + s0 * rBot);
                Vector3 vb1 = new Vector3(center.x + c1 * rBot, yBot, center.z + s1 * rBot);
                Vector3 vt0 = new Vector3(center.x + c0 * rTop, yTop, center.z + s0 * rTop);
                Vector3 vt1 = new Vector3(center.x + c1 * rTop, yTop, center.z + s1 * rTop);

                Vector3 norm = new Vector3((c0 + c1) * 0.5f, 0, (s0 + s1) * 0.5f).normalized;
                ctx.AddQuad(vb0, vt0, vt1, vb1, norm, col);

                if (rTop > 0.001f)
                {
                    ctx.AddTriangle(new Vector3(center.x, yTop, center.z), vt0, vt1, Vector3.up, Lighten(col, 0.1f));
                }
                if (rBot > 0.001f)
                {
                    ctx.AddTriangle(new Vector3(center.x, yBot, center.z), vb1, vb0, Vector3.down, Darken(col, 0.2f));
                }
            }
        }

        private static void AddCone(MeshBuilderContext ctx, Vector3 center, float r, float h, int segs, Color32 col)
        {
            AddCylinder(ctx, center + new Vector3(0, h * 0.5f, 0), r, 0.001f, h, segs, col);
        }

        private static void AddPyramid(MeshBuilderContext ctx, Vector3 center, Vector3 size, Color32 col)
        {
            float hx = size.x * 0.5f;
            float hz = size.z * 0.5f;
            float yBot = center.y - size.y * 0.5f;
            float yTop = center.y + size.y * 0.5f;
            Vector3 apex = new Vector3(center.x, yTop, center.z);

            Vector3 p0 = new Vector3(center.x - hx, yBot, center.z - hz);
            Vector3 p1 = new Vector3(center.x + hx, yBot, center.z - hz);
            Vector3 p2 = new Vector3(center.x + hx, yBot, center.z + hz);
            Vector3 p3 = new Vector3(center.x - hx, yBot, center.z + hz);

            ctx.AddTriangle(apex, p1, p0, new Vector3(0, 0.6f, -1).normalized, Darken(col, 0.08f));
            ctx.AddTriangle(apex, p2, p1, new Vector3(1, 0.6f, 0).normalized, Lighten(col, 0.06f));
            ctx.AddTriangle(apex, p3, p2, new Vector3(0, 0.6f, 1).normalized, col);
            ctx.AddTriangle(apex, p0, p3, new Vector3(-1, 0.6f, 0).normalized, Darken(col, 0.04f));

            ctx.AddQuad(p0, p1, p2, p3, Vector3.down, Darken(col, 0.2f));
        }

        private static void AddGableRoof(MeshBuilderContext ctx, Vector3 center, Vector3 size, float peakH, Color32 col, bool alongX = false)
        {
            float hx = size.x * 0.5f;
            float hz = size.z * 0.5f;
            float yBase = center.y + size.y * 0.5f;
            float yPeak = yBase + peakH;

            if (alongX)
            {
                Vector3 r0 = new Vector3(center.x - hx, yPeak, center.z);
                Vector3 r1 = new Vector3(center.x + hx, yPeak, center.z);
                Vector3 el0 = new Vector3(center.x - hx, yBase, center.z - hz);
                Vector3 el1 = new Vector3(center.x + hx, yBase, center.z - hz);
                Vector3 er0 = new Vector3(center.x - hx, yBase, center.z + hz);
                Vector3 er1 = new Vector3(center.x + hx, yBase, center.z + hz);

                ctx.AddQuad(el0, r0, r1, el1, new Vector3(0, 0.7f, -0.7f).normalized, Darken(col, 0.06f));
                ctx.AddQuad(r0, er0, er1, r1, new Vector3(0, 0.7f, 0.7f).normalized, Lighten(col, 0.06f));

                ctx.AddTriangle(r0, er0, el0, Vector3.left, Darken(col, 0.12f));
                ctx.AddTriangle(r1, el1, er1, Vector3.right, Lighten(col, 0.02f));
            }
            else
            {
                Vector3 r0 = new Vector3(center.x, yPeak, center.z - hz);
                Vector3 r1 = new Vector3(center.x, yPeak, center.z + hz);
                Vector3 el0 = new Vector3(center.x - hx, yBase, center.z - hz);
                Vector3 el1 = new Vector3(center.x - hx, yBase, center.z + hz);
                Vector3 er0 = new Vector3(center.x + hx, yBase, center.z - hz);
                Vector3 er1 = new Vector3(center.x + hx, yBase, center.z + hz);

                ctx.AddQuad(el0, el1, r1, r0, new Vector3(-0.7f, 0.7f, 0).normalized, Darken(col, 0.06f));
                ctx.AddQuad(r0, r1, er1, er0, new Vector3(0.7f, 0.7f, 0).normalized, Lighten(col, 0.06f));

                ctx.AddTriangle(r0, el0, er0, Vector3.back, Darken(col, 0.12f));
                ctx.AddTriangle(r1, er1, el1, Vector3.forward, Lighten(col, 0.02f));
            }
        }

        private static void AddTreePine(MeshBuilderContext ctx, Vector3 center, float trunkH, float trunkR, float folR, float folH)
        {
            Color32 tCol = new Color32(109, 76, 65, 255);
            AddCylinder(ctx, center + new Vector3(0, trunkH * 0.5f, 0), trunkR, trunkR * 0.9f, trunkH, 6, tCol);

            Color32 c1 = new Color32(27, 94, 32, 255);
            Color32 c2 = new Color32(46, 125, 50, 255);
            Color32 c3 = new Color32(56, 142, 60, 255);

            float stepH = folH * 0.42f;
            float y0 = center.y + trunkH * 0.7f;
            AddCone(ctx, new Vector3(center.x, y0, center.z), folR, stepH * 1.3f, 7, c1);
            AddCone(ctx, new Vector3(center.x, y0 + stepH * 0.65f, center.z), folR * 0.82f, stepH * 1.15f, 7, c2);
            AddCone(ctx, new Vector3(center.x, y0 + stepH * 1.35f, center.z), folR * 0.60f, stepH * 1.0f, 7, c3);
        }

        private static void AddTreeRound(MeshBuilderContext ctx, Vector3 center, float trunkH, float trunkR, float folR, Color32 col)
        {
            AddCylinder(ctx, center + new Vector3(0, trunkH * 0.5f, 0), trunkR, trunkR, trunkH, 6, new Color32(121, 85, 72, 255));
            AddCylinder(ctx, center + new Vector3(0, trunkH + folR * 0.75f, 0), folR * 0.7f, folR * 0.95f, folR * 1.1f, 7, col);
            AddCylinder(ctx, center + new Vector3(0, trunkH + folR * 1.45f, 0), folR * 0.95f, folR * 0.4f, folR * 0.8f, 7, Lighten(col, 0.08f));
        }

        private static void AddCar(MeshBuilderContext ctx, Vector3 center, Vector3 size, Color32 bodyCol, float rotY)
        {
            float baseH = size.y * 0.45f;
            float cabH = size.y * 0.55f;

            AddBox(ctx, center + new Vector3(0, baseH * 0.5f, 0), size, bodyCol);
            Vector3 cabSize = new Vector3(size.x * 0.78f, cabH, size.z * 0.58f);
            Vector3 cabPos = center + new Vector3(0, baseH + cabH * 0.5f, -size.z * 0.08f);
            AddBox(ctx, cabPos, cabSize, Lighten(bodyCol, 0.1f));

            // Windows
            AddBox(ctx, cabPos + new Vector3(0, 0, cabSize.z * 0.52f), new Vector3(cabSize.x * 0.85f, cabH * 0.7f, 0.04f), new Color32(30, 41, 59, 255));
            AddBox(ctx, cabPos - new Vector3(0, 0, cabSize.z * 0.52f), new Vector3(cabSize.x * 0.85f, cabH * 0.7f, 0.04f), new Color32(30, 41, 59, 255));
            // Headlights
            AddBox(ctx, center + new Vector3(size.x * 0.28f, baseH * 0.55f, size.z * 0.51f), new Vector3(size.x * 0.22f, baseH * 0.35f, 0.04f), new Color32(254, 240, 138, 255));
            AddBox(ctx, center + new Vector3(-size.x * 0.28f, baseH * 0.55f, size.z * 0.51f), new Vector3(size.x * 0.22f, baseH * 0.35f, 0.04f), new Color32(254, 240, 138, 255));
        }

        private static void AddStripedAwning(MeshBuilderContext ctx, Vector3 center, Vector3 size, Color32 col1, Color32 col2, int stripes = 5)
        {
            float stripeW = size.x / stripes;
            float startX = center.x - size.x * 0.5f;
            for (int s = 0; s < stripes; s++)
            {
                Color32 c = (s % 2 == 0) ? col1 : col2;
                Vector3 pos = new Vector3(startX + (s + 0.5f) * stripeW, center.y, center.z);
                float hx = stripeW * 0.5f;
                float hy = size.y * 0.5f;
                float hz = size.z * 0.5f;

                Vector3 p0 = pos + new Vector3(-hx, hy, -hz);
                Vector3 p1 = pos + new Vector3( hx, hy, -hz);
                Vector3 p2 = pos + new Vector3( hx, -hy, hz);
                Vector3 p3 = pos + new Vector3(-hx, -hy, hz);
                ctx.AddQuad(p0, p1, p2, p3, new Vector3(0, 0.6f, 0.8f).normalized, c);
            }
        }

        // ==============================================================================
        // 1. SMALL CITY MESH
        // ==============================================================================
        public static Mesh BuildSmallCityMesh()
        {
            var ctx = new MeshBuilderContext();

            // 1. Island pedestal base
            Color32 baseCol = new Color32(132, 204, 22, 255); // Vibrant meadow green
            AddCylinder(ctx, new Vector3(0, 0.10f, 0), 3.25f, 3.15f, 0.20f, 22, baseCol);

            // 2. Village curved sand paths
            Color32 pathCol = new Color32(229, 215, 173, 255);
            AddCylinder(ctx, new Vector3(0.1f, 0.21f, 0.1f), 1.25f, 1.25f, 0.02f, 14, pathCol);
            AddBox(ctx, new Vector3(-0.9f, 0.21f, 0.4f), new Vector3(1.6f, 0.02f, 0.65f), pathCol);
            AddBox(ctx, new Vector3(0.8f, 0.21f, -0.6f), new Vector3(0.7f, 0.02f, 1.6f), pathCol);
            AddBox(ctx, new Vector3(0.4f, 0.21f, 1.3f), new Vector3(1.8f, 0.02f, 0.6f), pathCol);

            // 3. Garden plot
            Color32 soilCol = new Color32(121, 85, 72, 255);
            Color32 cropCol = new Color32(76, 175, 80, 255);
            Vector3 gardenPos = new Vector3(1.7f, 0.22f, 1.4f);
            AddBox(ctx, gardenPos, new Vector3(1.3f, 0.04f, 0.95f), soilCol);
            for (int r = 0; r < 2; r++)
            {
                for (int c = 0; c < 3; c++)
                {
                    float cx = gardenPos.x - 0.4f + c * 0.4f;
                    float cz = gardenPos.z - 0.2f + r * 0.4f;
                    AddCylinder(ctx, new Vector3(cx, 0.27f, cz), 0.09f, 0.07f, 0.08f, 6, cropCol);
                }
            }

            // 4. Stylized pine trees & round bushes
            AddTreePine(ctx, new Vector3(1.8f, 0.20f, -1.8f), 0.7f, 0.09f, 0.55f, 1.3f);
            AddTreePine(ctx, new Vector3(2.4f, 0.20f, -1.0f), 0.9f, 0.11f, 0.70f, 1.6f);
            AddTreePine(ctx, new Vector3(2.6f, 0.20f, 0.1f), 0.75f, 0.10f, 0.60f, 1.4f);

            Color32 bushCol = new Color32(74, 222, 128, 255);
            AddTreeRound(ctx, new Vector3(-2.2f, 0.20f, -0.3f), 0.2f, 0.06f, 0.38f, bushCol);
            AddTreeRound(ctx, new Vector3(-2.0f, 0.20f, 0.4f), 0.15f, 0.05f, 0.32f, Lighten(bushCol, 0.06f));
            AddTreeRound(ctx, new Vector3(-1.8f, 0.20f, -1.1f), 0.18f, 0.05f, 0.35f, Darken(bushCol, 0.06f));
            AddTreeRound(ctx, new Vector3(1.9f, 0.20f, 2.3f), 0.12f, 0.04f, 0.28f, bushCol);

            // 5. Central Village Church
            Color32 wallCream = new Color32(253, 251, 247, 255);
            Color32 roofTerra = new Color32(234, 88, 12, 255);
            Color32 doorWood = new Color32(92, 61, 46, 255);
            Color32 winBlue = new Color32(56, 189, 248, 255);
            Color32 goldCol = new Color32(251, 191, 36, 255);

            Vector3 towerPos = new Vector3(-0.6f, 0.90f, -0.9f);
            AddBox(ctx, towerPos, new Vector3(0.85f, 1.4f, 0.85f), wallCream);
            AddPyramid(ctx, towerPos + new Vector3(0, 1.05f, 0), new Vector3(1.0f, 0.7f, 1.0f), roofTerra);
            AddCylinder(ctx, towerPos + new Vector3(0, 1.5f, 0), 0.04f, 0.01f, 0.2f, 6, goldCol);
            AddBox(ctx, towerPos + new Vector3(0, -0.35f, 0.44f), new Vector3(0.3f, 0.6f, 0.04f), doorWood);
            AddBox(ctx, towerPos + new Vector3(0, 0.35f, 0.44f), new Vector3(0.24f, 0.45f, 0.04f), winBlue);

            Vector3 hallPos = new Vector3(0.25f, 0.80f, -0.9f);
            AddBox(ctx, hallPos, new Vector3(1.0f, 1.2f, 0.85f), wallCream);
            AddGableRoof(ctx, hallPos, new Vector3(1.15f, 0.3f, 0.95f), 0.55f, roofTerra, true);
            AddBox(ctx, hallPos + new Vector3(-0.25f, 0.1f, 0.44f), new Vector3(0.2f, 0.35f, 0.03f), winBlue);
            AddBox(ctx, hallPos + new Vector3( 0.25f, 0.1f, 0.44f), new Vector3(0.2f, 0.35f, 0.03f), winBlue);

            // 6. Two-story village house
            Vector3 h1Pos = new Vector3(1.4f, 0.95f, -0.3f);
            AddBox(ctx, h1Pos, new Vector3(1.25f, 1.5f, 1.15f), wallCream);
            AddGableRoof(ctx, h1Pos, new Vector3(1.4f, 0.2f, 1.3f), 0.65f, roofTerra, false);
            AddBox(ctx, h1Pos + new Vector3(-0.25f, -0.45f, 0.59f), new Vector3(0.28f, 0.55f, 0.03f), doorWood);
            AddBox(ctx, h1Pos + new Vector3( 0.32f, -0.45f, 0.59f), new Vector3(0.22f, 0.28f, 0.03f), winBlue);
            AddBox(ctx, h1Pos + new Vector3(-0.32f,  0.30f, 0.59f), new Vector3(0.22f, 0.28f, 0.03f), winBlue);
            AddBox(ctx, h1Pos + new Vector3( 0.32f,  0.30f, 0.59f), new Vector3(0.22f, 0.28f, 0.03f), winBlue);

            // 7. Front cottage
            Vector3 h2Pos = new Vector3(-0.2f, 0.65f, 0.8f);
            AddBox(ctx, h2Pos, new Vector3(1.05f, 0.9f, 0.95f), wallCream);
            AddGableRoof(ctx, h2Pos, new Vector3(1.2f, 0.2f, 1.1f), 0.55f, roofTerra, false);
            AddBox(ctx, h2Pos + new Vector3(-0.22f, -0.2f, 0.49f), new Vector3(0.25f, 0.50f, 0.03f), doorWood);
            AddBox(ctx, h2Pos + new Vector3( 0.24f, -0.15f, 0.49f), new Vector3(0.20f, 0.25f, 0.03f), winBlue);

            // 8. Left cottage
            Vector3 h3Pos = new Vector3(-1.6f, 0.60f, -0.3f);
            AddBox(ctx, h3Pos, new Vector3(0.95f, 0.8f, 0.90f), wallCream);
            AddGableRoof(ctx, h3Pos, new Vector3(1.1f, 0.2f, 1.0f), 0.50f, roofTerra, false);
            AddBox(ctx, h3Pos + new Vector3(0.22f, -0.15f, 0.46f), new Vector3(0.25f, 0.45f, 0.03f), doorWood);
            AddBox(ctx, h3Pos + new Vector3(-0.22f, -0.10f, 0.46f), new Vector3(0.20f, 0.24f, 0.03f), winBlue);

            // 9. Flag base pedestal
            AddCylinder(ctx, new Vector3(0.1f, 0.32f, 0.0f), 0.35f, 0.28f, 0.16f, 12, new Color32(203, 213, 225, 255));

            return ctx.ToMesh("Mesh_SmallCity");
        }

        // ==============================================================================
        // 2. MEDIUM CITY MESH
        // ==============================================================================
        public static Mesh BuildMediumCityMesh()
        {
            var ctx = new MeshBuilderContext();

            // 1. Street grid podium (5.6 x 5.6)
            Color32 roadCol = new Color32(51, 65, 85, 255);    // Dark asphalt
            Color32 curbCol = new Color32(203, 213, 225, 255); // Concrete sidewalk
            Color32 parkCol = new Color32(101, 163, 13, 255);  // Park grass
            Color32 lineCol = new Color32(248, 250, 252, 255); // White markings

            AddBox(ctx, new Vector3(0, 0.08f, 0), new Vector3(5.6f, 0.16f, 5.6f), roadCol);

            float bOffset = 1.7f;
            float bSize = 1.8f;
            float bH = 0.22f;
            AddBox(ctx, new Vector3(-bOffset, bH * 0.5f, -bOffset), new Vector3(bSize, bH, bSize), curbCol);
            AddBox(ctx, new Vector3( bOffset, bH * 0.5f, -bOffset), new Vector3(bSize, bH, bSize), curbCol);
            AddBox(ctx, new Vector3(-bOffset, bH * 0.5f,  bOffset), new Vector3(bSize, bH, bSize), curbCol);
            AddBox(ctx, new Vector3( bOffset, bH * 0.5f,  bOffset), new Vector3(bSize, bH, bSize), curbCol);

            // Central public square
            AddBox(ctx, new Vector3(0, 0.22f, 0), new Vector3(1.3f, 0.06f, 1.3f), parkCol);
            AddCylinder(ctx, new Vector3(0, 0.32f, 0), 0.35f, 0.26f, 0.16f, 12, curbCol);

            // Crosswalk zebra stripes
            for (int i = 0; i < 4; i++)
            {
                float zx = -0.35f + i * 0.23f;
                AddBox(ctx, new Vector3(zx, 0.17f, -0.75f), new Vector3(0.12f, 0.01f, 0.35f), lineCol);
                AddBox(ctx, new Vector3(zx, 0.17f,  0.75f), new Vector3(0.12f, 0.01f, 0.35f), lineCol);
                AddBox(ctx, new Vector3(-0.75f, 0.17f, zx), new Vector3(0.35f, 0.01f, 0.12f), lineCol);
                AddBox(ctx, new Vector3( 0.75f, 0.17f, zx), new Vector3(0.35f, 0.01f, 0.12f), lineCol);
            }

            // Trees
            Color32 treeCol = new Color32(34, 197, 94, 255);
            AddTreeRound(ctx, new Vector3(-0.45f, 0.24f, -0.45f), 0.3f, 0.05f, 0.22f, treeCol);
            AddTreeRound(ctx, new Vector3( 0.45f, 0.24f, -0.45f), 0.3f, 0.05f, 0.22f, treeCol);
            AddTreeRound(ctx, new Vector3(-0.45f, 0.24f,  0.45f), 0.3f, 0.05f, 0.22f, treeCol);
            AddTreeRound(ctx, new Vector3( 0.45f, 0.24f,  0.45f), 0.3f, 0.05f, 0.22f, treeCol);

            // Mixed-rise Town Buildings
            Color32 bRed = new Color32(185, 28, 28, 255);
            Color32 bTan = new Color32(217, 119, 6, 255);
            Color32 bBlue = new Color32(2, 132, 199, 255);
            Color32 bCream = new Color32(254, 243, 199, 255);
            Color32 bBrown = new Color32(120, 53, 15, 255);
            Color32 roofGray = new Color32(71, 85, 105, 255);
            Color32 awningRed = new Color32(239, 68, 68, 255);
            Color32 awningWht = new Color32(255, 255, 255, 255);
            Color32 awningOrg = new Color32(249, 115, 22, 255);

            // Block 1: Top-Left (Town Hall & Clock Tower)
            Vector3 b1Pos = new Vector3(-1.8f, 1.25f, -2.0f);
            AddBox(ctx, b1Pos, new Vector3(1.1f, 2.1f, 0.95f), bBlue);
            AddBox(ctx, b1Pos + new Vector3(0, 1.08f, 0), new Vector3(1.15f, 0.08f, 1.0f), roofGray);
            for (int f = 0; f < 3; f++)
            {
                float fy = b1Pos.y - 0.5f + f * 0.55f;
                AddBox(ctx, new Vector3(b1Pos.x, fy, b1Pos.z + 0.49f), new Vector3(0.85f, 0.25f, 0.02f), new Color32(186, 230, 253, 255));
            }
            Vector3 towerPos = new Vector3(-1.8f, 2.6f, -2.0f);
            AddBox(ctx, towerPos, new Vector3(0.65f, 1.8f, 0.65f), Darken(bBlue, 0.12f));
            AddPyramid(ctx, towerPos + new Vector3(0, 1.3f, 0), new Vector3(0.85f, 0.9f, 0.85f), new Color32(13, 148, 136, 255));
            AddBox(ctx, towerPos + new Vector3(0, 0.45f, 0.33f), new Vector3(0.28f, 0.28f, 0.03f), new Color32(254, 240, 138, 255)); // Clock face

            // Cottage near town hall
            Vector3 b2Pos = new Vector3(-2.0f, 0.85f, -1.1f);
            AddBox(ctx, b2Pos, new Vector3(0.8f, 1.3f, 0.75f), bCream);
            AddGableRoof(ctx, b2Pos, new Vector3(0.9f, 0.15f, 0.85f), 0.35f, new Color32(234, 88, 12, 255), true);

            // Block 2: Top-Right (Red brick apartment & shop)
            Vector3 b3Pos = new Vector3(1.9f, 1.45f, -1.8f);
            AddBox(ctx, b3Pos, new Vector3(1.0f, 2.5f, 0.95f), bRed);
            AddBox(ctx, b3Pos + new Vector3(0, 1.28f, 0), new Vector3(1.06f, 0.1f, 1.01f), roofGray);
            AddBox(ctx, b3Pos + new Vector3(0.15f, 1.45f, 0.1f), new Vector3(0.3f, 0.25f, 0.3f), new Color32(100, 116, 139, 255));
            for (int f = 0; f < 4; f++)
            {
                float fy = b3Pos.y - 0.8f + f * 0.52f;
                AddBox(ctx, new Vector3(b3Pos.x, fy, b3Pos.z + 0.49f), new Vector3(0.75f, 0.22f, 0.02f), new Color32(254, 240, 138, 255));
            }

            Vector3 b4Pos = new Vector3(1.4f, 0.95f, -1.0f);
            AddBox(ctx, b4Pos, new Vector3(0.9f, 1.5f, 0.75f), bTan);
            AddStripedAwning(ctx, b4Pos + new Vector3(0, -0.2f, 0.42f), new Vector3(0.8f, 0.22f, 0.28f), awningRed, awningWht, 5);

            // Block 3: Bottom-Left (Cafe with orange awning & townhouse)
            Vector3 b5Pos = new Vector3(-1.4f, 0.85f, 1.3f);
            AddBox(ctx, b5Pos, new Vector3(0.95f, 1.3f, 0.8f), bCream);
            AddStripedAwning(ctx, b5Pos + new Vector3(0, -0.15f, 0.44f), new Vector3(0.85f, 0.22f, 0.26f), awningOrg, awningWht, 5);

            Vector3 b6Pos = new Vector3(-2.0f, 1.25f, 1.9f);
            AddBox(ctx, b6Pos, new Vector3(0.95f, 2.1f, 0.9f), bBrown);
            AddBox(ctx, b6Pos + new Vector3(0, 1.1f, 0), new Vector3(1.0f, 0.12f, 0.95f), new Color32(51, 65, 85, 255));

            // Block 4: Bottom-Right (Modern commercial block)
            Vector3 b7Pos = new Vector3(1.8f, 1.15f, 1.5f);
            AddBox(ctx, b7Pos, new Vector3(1.2f, 1.9f, 1.1f), new Color32(3, 105, 161, 255));
            AddBox(ctx, b7Pos + new Vector3(0, 0.98f, 0), new Vector3(1.25f, 0.08f, 1.15f), roofGray);
            AddBox(ctx, b7Pos + new Vector3(0, -0.5f, 0.57f), new Vector3(0.95f, 0.5f, 0.02f), new Color32(56, 189, 248, 255));

            // Miniature cars
            AddCar(ctx, new Vector3(0.4f, 0.22f, -1.8f), new Vector3(0.28f, 0.22f, 0.55f), new Color32(234, 179, 8, 255), 0); // Yellow taxi
            AddCar(ctx, new Vector3(-0.4f, 0.22f, 1.8f), new Vector3(0.28f, 0.22f, 0.55f), new Color32(239, 68, 68, 255), Mathf.PI); // Red sedan
            AddCar(ctx, new Vector3(1.8f, 0.22f, 0.4f), new Vector3(0.55f, 0.22f, 0.28f), new Color32(59, 130, 246, 255), Mathf.PI * 0.5f); // Blue car

            return ctx.ToMesh("Mesh_MediumCity");
        }

        // ==============================================================================
        // 3. LARGE METROPOLIS MESH
        // ==============================================================================
        public static Mesh BuildLargeCityMesh()
        {
            var ctx = new MeshBuilderContext();

            // 1. Urban Podium (8.0 x 8.0)
            Color32 podCol = new Color32(30, 41, 59, 255);
            Color32 paveCol = new Color32(71, 85, 105, 255);
            Color32 waterCol = new Color32(2, 132, 199, 255);
            Color32 lawnCol = new Color32(77, 124, 15, 255);

            AddBox(ctx, new Vector3(0, 0.12f, 0), new Vector3(8.0f, 0.24f, 8.0f), podCol);
            AddBox(ctx, new Vector3(0, 0.26f, 0), new Vector3(7.8f, 0.06f, 7.8f), paveCol);

            // Water canal & boat
            Vector3 waterPos = new Vector3(2.5f, 0.26f, 2.5f);
            AddBox(ctx, waterPos, new Vector3(2.6f, 0.06f, 2.6f), waterCol);
            AddBox(ctx, waterPos + new Vector3(0.4f, 0.10f, 0.3f), new Vector3(0.55f, 0.14f, 0.28f), new Color32(248, 250, 252, 255));
            AddBox(ctx, waterPos + new Vector3(0.4f, 0.20f, 0.3f), new Vector3(0.28f, 0.12f, 0.20f), new Color32(56, 189, 248, 255));

            // Avenue Park
            Vector3 parkPos = new Vector3(-2.2f, 0.30f, 2.2f);
            AddBox(ctx, parkPos, new Vector3(2.8f, 0.04f, 2.8f), lawnCol);
            for (int tx = 0; tx < 3; tx++)
            {
                for (int tz = 0; tz < 3; tz++)
                {
                    float px = parkPos.x - 0.9f + tx * 0.9f;
                    float pz = parkPos.z - 0.9f + tz * 0.9f;
                    AddCone(ctx, new Vector3(px, 0.32f, pz), 0.28f, 0.95f, 7, new Color32(21, 128, 61, 255));
                }
            }

            // 2. Skyscraper 1: Glass Supertall with Helipad
            Vector3 s1Pos = new Vector3(-1.2f, 3.5f, -1.2f);
            float s1H = 6.6f;
            AddBox(ctx, new Vector3(s1Pos.x, s1H * 0.5f + 0.3f, s1Pos.z), new Vector3(1.5f, s1H, 1.5f), new Color32(15, 23, 42, 255));
            // Mullions
            AddBox(ctx, new Vector3(s1Pos.x - 0.72f, s1H * 0.5f + 0.3f, s1Pos.z - 0.72f), new Vector3(0.12f, s1H, 0.12f), new Color32(203, 213, 225, 255));
            AddBox(ctx, new Vector3(s1Pos.x + 0.72f, s1H * 0.5f + 0.3f, s1Pos.z - 0.72f), new Vector3(0.12f, s1H, 0.12f), new Color32(203, 213, 225, 255));
            AddBox(ctx, new Vector3(s1Pos.x - 0.72f, s1H * 0.5f + 0.3f, s1Pos.z + 0.72f), new Vector3(0.12f, s1H, 0.12f), new Color32(203, 213, 225, 255));
            AddBox(ctx, new Vector3(s1Pos.x + 0.72f, s1H * 0.5f + 0.3f, s1Pos.z + 0.72f), new Vector3(0.12f, s1H, 0.12f), new Color32(203, 213, 225, 255));
            // Glass window strips
            for (int l = 0; l < 8; l++)
            {
                float ly = 1.0f + l * 0.7f;
                AddBox(ctx, new Vector3(s1Pos.x, ly, s1Pos.z + 0.76f), new Vector3(1.3f, 0.18f, 0.02f), new Color32(56, 189, 248, 255));
                AddBox(ctx, new Vector3(s1Pos.x, ly, s1Pos.z - 0.76f), new Vector3(1.3f, 0.18f, 0.02f), new Color32(56, 189, 248, 255));
            }
            // Helipad on roof
            float heliY = s1H + 0.32f;
            AddCylinder(ctx, new Vector3(s1Pos.x, heliY, s1Pos.z), 0.65f, 0.65f, 0.05f, 14, new Color32(51, 65, 85, 255));
            AddBox(ctx, new Vector3(s1Pos.x - 0.18f, heliY + 0.04f, s1Pos.z), new Vector3(0.08f, 0.02f, 0.36f), new Color32(250, 204, 21, 255));
            AddBox(ctx, new Vector3(s1Pos.x + 0.18f, heliY + 0.04f, s1Pos.z), new Vector3(0.08f, 0.02f, 0.36f), new Color32(250, 204, 21, 255));
            AddBox(ctx, new Vector3(s1Pos.x, heliY + 0.04f, s1Pos.z), new Vector3(0.28f, 0.02f, 0.08f), new Color32(250, 204, 21, 255));

            // 3. Skyscraper 2: Grand Gateway Arch Tower
            Vector3 s2Pos = new Vector3(1.3f, 2.9f, -1.3f);
            float s2H = 5.4f;
            AddBox(ctx, new Vector3(s2Pos.x - 0.5f, s2H * 0.5f + 0.3f, s2Pos.z), new Vector3(0.6f, s2H, 1.2f), new Color32(30, 58, 138, 255));
            AddBox(ctx, new Vector3(s2Pos.x + 0.5f, s2H * 0.5f + 0.3f, s2Pos.z), new Vector3(0.6f, s2H, 1.2f), new Color32(30, 58, 138, 255));
            // Portal bridge on top
            AddBox(ctx, new Vector3(s2Pos.x, s2H + 0.1f, s2Pos.z), new Vector3(1.8f, 0.45f, 1.25f), new Color32(234, 179, 8, 255)); // Gold crown

            // 4. Central Landmark Spire
            AddCylinder(ctx, new Vector3(0, 3.8f, 0), 0.22f, 0.02f, 4.5f, 8, new Color32(251, 191, 36, 255)); // Golden Needle Spire

            return ctx.ToMesh("Mesh_LargeCity");
        }
    }
}
