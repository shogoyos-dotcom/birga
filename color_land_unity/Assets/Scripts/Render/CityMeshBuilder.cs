using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — 3D Qasr va Saroylar Geometriyasi Yaratuvchisi (Castle & Palace Mesh Builder).
    /// Foydalanuvchi taqdim etgan etalon dizaynga (Berlin [DE], Tashkent [UZ], Samarkand [UZ], Dubai [AE])
    /// 100% mos: ertaknamo qasrlar, sharqona feruza/oltin gumbazli saroylar,
    /// arkaturalar, minoralar, darvozalar va bayroq ustunlari.
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
                var mesh = new Mesh { name = name };
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

            ctx.AddQuad(p3, p2, p6, p7, Vector3.up, Lighten(col, 0.12f));
            ctx.AddQuad(p4, p5, p1, p0, Vector3.down, Darken(col, 0.25f));
            ctx.AddQuad(p4, p7, p6, p5, Vector3.forward, col);
            ctx.AddQuad(p1, p2, p3, p0, Vector3.back, Darken(col, 0.12f));
            ctx.AddQuad(p0, p3, p7, p4, Vector3.left, Darken(col, 0.08f));
            ctx.AddQuad(p5, p6, p2, p1, Vector3.right, Lighten(col, 0.06f));
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
                    ctx.AddTriangle(new Vector3(center.x, yTop, center.z), vt0, vt1, Vector3.up, Lighten(col, 0.12f));
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

        private static void AddDome(MeshBuilderContext ctx, Vector3 center, float radius, Color32 col, int rings = 6, int segs = 12)
        {
            for (int r = 0; r < rings; r++)
            {
                float phi0 = (float)r / rings * (Mathf.PI * 0.5f);
                float phi1 = (float)(r + 1) / rings * (Mathf.PI * 0.5f);

                float y0 = center.y + Mathf.Sin(phi0) * radius;
                float y1 = center.y + Mathf.Sin(phi1) * radius;

                float r0 = Mathf.Cos(phi0) * radius;
                float r1 = Mathf.Cos(phi1) * radius;

                float step = Mathf.PI * 2.0f / segs;
                for (int i = 0; i < segs; i++)
                {
                    float a0 = i * step;
                    float a1 = (i + 1) * step;

                    Vector3 v00 = new Vector3(center.x + Mathf.Cos(a0) * r0, y0, center.z + Mathf.Sin(a0) * r0);
                    Vector3 v10 = new Vector3(center.x + Mathf.Cos(a1) * r0, y0, center.z + Mathf.Sin(a1) * r0);
                    Vector3 v01 = new Vector3(center.x + Mathf.Cos(a0) * r1, y1, center.z + Mathf.Sin(a0) * r1);
                    Vector3 v11 = new Vector3(center.x + Mathf.Cos(a1) * r1, y1, center.z + Mathf.Sin(a1) * r1);

                    Vector3 norm = (v00 - center).normalized;
                    ctx.AddQuad(v00, v01, v11, v10, norm, col);
                }
            }
        }

        // ==============================================================================
        // 1. SMALL CITY: Ertaknamo Oq Qasr (Fairytale Castle / Samarkand Style)
        // ==============================================================================
        public static Mesh BuildSmallCityMesh()
        {
            var ctx = new MeshBuilderContext();

            Color32 wallWhite = new Color32(245, 243, 238, 255);
            Color32 wallGold = new Color32(245, 210, 140, 255);
            Color32 roofTurquoise = new Color32(14, 165, 233, 255);
            Color32 domeGold = new Color32(251, 191, 36, 255);
            Color32 doorBrown = new Color32(92, 61, 46, 255);
            Color32 podiumStone = new Color32(203, 213, 225, 255);

            // 1. Tosh poydevor platforma
            AddCylinder(ctx, new Vector3(0, 0.12f, 0), 3.4f, 3.2f, 0.24f, 20, podiumStone);

            // 2. Markaziy Saroy Binosi (Main Palace Keep)
            AddBox(ctx, new Vector3(0, 1.0f, 0), new Vector3(2.0f, 1.6f, 1.8f), wallWhite);
            AddBox(ctx, new Vector3(0, 1.85f, 0), new Vector3(2.15f, 0.1f, 1.95f), wallGold);

            // 3. Markaziy Asosiy Gumbaz (Main Center Dome)
            AddDome(ctx, new Vector3(0, 1.9f, 0), 0.95f, roofTurquoise, 6, 14);
            // Gumbaz ustidagi oltin shpil
            AddCylinder(ctx, new Vector3(0, 3.0f, 0), 0.05f, 0.01f, 0.45f, 6, domeGold);
            AddDome(ctx, new Vector3(0, 3.25f, 0), 0.12f, domeGold, 4, 8);

            // 4. 4 ta Burchak Qasr Minorasi (4 Corner Palace Towers)
            float[] txs = new float[] { -1.15f, 1.15f, -1.15f, 1.15f };
            float[] tzs = new float[] { -1.05f, -1.05f, 1.05f, 1.05f };

            for (int i = 0; i < 4; i++)
            {
                Vector3 tPos = new Vector3(txs[i], 1.25f, tzs[i]);
                AddCylinder(ctx, tPos, 0.38f, 0.34f, 2.3f, 8, wallWhite);
                AddBox(ctx, tPos + new Vector3(0, 1.18f, 0), new Vector3(0.85f, 0.12f, 0.85f), wallGold);
                // Minora gumbazi
                AddCone(ctx, tPos + new Vector3(0, 1.25f, 0), 0.46f, 0.95f, 8, domeGold);
            }

            // 5. Arkali Darvoza (Portal Arch)
            AddBox(ctx, new Vector3(0, 0.65f, 0.92f), new Vector3(0.75f, 1.1f, 0.15f), wallGold);
            AddBox(ctx, new Vector3(0, 0.5f, 0.96f), new Vector3(0.45f, 0.85f, 0.10f), doorBrown);

            return ctx.ToMesh("Mesh_SmallCastle");
        }

        // ==============================================================================
        // 2. MEDIUM CITY: Sharqona Zangori/Oltin Saroy (Samarkand / Dubai Style)
        // ==============================================================================
        public static Mesh BuildMediumCityMesh()
        {
            var ctx = new MeshBuilderContext();

            Color32 wallCream = new Color32(248, 250, 252, 255);
            Color32 wallGold = new Color32(245, 190, 80, 255);
            Color32 domeCyan = new Color32(2, 132, 199, 255);
            Color32 domeGold = new Color32(234, 179, 8, 255);
            Color32 archBlue = new Color32(3, 105, 161, 255);
            Color32 podiumBase = new Color32(148, 163, 184, 255);

            // 1. Keng saroy poydevori
            AddBox(ctx, new Vector3(0, 0.15f, 0), new Vector3(5.2f, 0.30f, 4.8f), podiumBase);
            AddBox(ctx, new Vector3(0, 0.32f, 0), new Vector3(5.0f, 0.08f, 4.6f), new Color32(226, 232, 240, 255));

            // 2. Registon uslubidagi Markaziy Peshtoq (Grand Entrance Portal / Pishtaq)
            Vector3 pishtaqPos = new Vector3(0, 1.6f, 1.1f);
            AddBox(ctx, pishtaqPos, new Vector3(2.4f, 2.6f, 0.9f), wallCream);
            // Peshtoq hoshiyasi va koshin naqshi
            AddBox(ctx, pishtaqPos + new Vector3(0, 1.35f, 0), new Vector3(2.5f, 0.22f, 0.95f), wallGold);
            AddBox(ctx, pishtaqPos + new Vector3(0, -0.1f, 0.46f), new Vector3(1.3f, 1.8f, 0.12f), archBlue);
            AddBox(ctx, pishtaqPos + new Vector3(0, -0.3f, 0.48f), new Vector3(0.85f, 1.3f, 0.12f), new Color32(30, 41, 59, 255));

            // 3. Asosiy Katta Gumbaz (Grand Turquoise Dome)
            Vector3 domePos = new Vector3(0, 2.45f, -0.4f);
            AddCylinder(ctx, domePos, 1.25f, 1.25f, 1.2f, 16, wallCream);
            AddDome(ctx, domePos + new Vector3(0, 0.6f, 0), 1.35f, domeCyan, 6, 16);
            AddCylinder(ctx, domePos + new Vector3(0, 2.05f, 0), 0.08f, 0.02f, 0.7f, 6, domeGold);

            // 4. Yon qanotlar (Side Wings)
            AddBox(ctx, new Vector3(-1.8f, 1.0f, -0.2f), new Vector3(1.4f, 1.5f, 2.2f), wallCream);
            AddBox(ctx, new Vector3( 1.8f, 1.0f, -0.2f), new Vector3(1.4f, 1.5f, 2.2f), wallCream);
            AddDome(ctx, new Vector3(-1.8f, 1.85f, -0.2f), 0.75f, domeGold, 5, 12);
            AddDome(ctx, new Vector3( 1.8f, 1.85f, -0.2f), 0.75f, domeGold, 5, 12);

            // 5. 2 ta Baland Minoralar (2 Grand Minarets)
            for (int m = -1; m <= 1; m += 2)
            {
                Vector3 mPos = new Vector3(m * 2.3f, 2.2f, 1.6f);
                AddCylinder(ctx, mPos, 0.35f, 0.28f, 4.0f, 10, wallCream);
                AddCylinder(ctx, mPos + new Vector3(0, 2.05f, 0), 0.42f, 0.42f, 0.22f, 10, wallGold);
                AddDome(ctx, mPos + new Vector3(0, 2.25f, 0), 0.32f, domeCyan, 4, 10);
                AddCylinder(ctx, mPos + new Vector3(0, 2.65f, 0), 0.04f, 0.01f, 0.35f, 6, domeGold);
            }

            return ctx.ToMesh("Mesh_MediumPalace");
        }

        // ==============================================================================
        // 3. LARGE CITY: Qirollik Qasri (Grand Imperial Castle / Berlin [DE] & Tashkent [UZ] Style)
        // ==============================================================================
        public static Mesh BuildLargeCityMesh()
        {
            var ctx = new MeshBuilderContext();

            Color32 wallStone = new Color32(248, 250, 252, 255);
            Color32 roofRed = new Color32(220, 38, 38, 255);       // Berlin qizil tomi
            Color32 trimGold = new Color32(251, 191, 36, 255);     // Oltin hoshiyalar
            Color32 turretRoof = new Color32(185, 28, 28, 255);
            Color32 windowDark = new Color32(30, 41, 59, 255);
            Color32 baseGranite = new Color32(71, 85, 105, 255);

            // 1. Katta granit shahar poydevori
            AddBox(ctx, new Vector3(0, 0.2f, 0), new Vector3(6.8f, 0.40f, 6.2f), baseGranite);
            AddBox(ctx, new Vector3(0, 0.42f, 0), new Vector3(6.5f, 0.12f, 5.9f), new Color32(203, 213, 225, 255));

            // 2. Markaziy Monumental Saroy Korpus (Central Imperial Palace)
            AddBox(ctx, new Vector3(0, 1.8f, 0), new Vector3(3.4f, 2.6f, 2.8f), wallStone);
            AddBox(ctx, new Vector3(0, 3.15f, 0), new Vector3(3.55f, 0.18f, 2.95f), trimGold);

            // Markaziy saroy mansard tomi (Royal mansard roof)
            AddBox(ctx, new Vector3(0, 3.7f, 0), new Vector3(3.0f, 1.0f, 2.4f), roofRed);

            // 3. Markaziy Katta Minora va Shpil (Grand Sovereign Tower & Spire)
            Vector3 towerPos = new Vector3(0, 4.6f, 0);
            AddBox(ctx, towerPos, new Vector3(1.4f, 1.8f, 1.4f), wallStone);
            AddBox(ctx, towerPos + new Vector3(0, 0.95f, 0), new Vector3(1.55f, 0.15f, 1.55f), trimGold);
            AddCone(ctx, towerPos + new Vector3(0, 1.05f, 0), 1.1f, 2.8f, 8, turretRoof); // Baland qizil shpil
            AddCylinder(ctx, towerPos + new Vector3(0, 3.85f, 0), 0.08f, 0.02f, 0.8f, 6, trimGold); // Oltin shtil

            // 4. 4 ta Burchak Qasr Qal'a Minorasi (4 Sovereign Bastion Towers)
            float[] bxs = new float[] { -2.0f, 2.0f, -2.0f, 2.0f };
            float[] bzs = new float[] { -1.8f, -1.8f, 1.8f, 1.8f };

            for (int i = 0; i < 4; i++)
            {
                Vector3 bPos = new Vector3(bxs[i], 2.2f, bzs[i]);
                AddCylinder(ctx, bPos, 0.65f, 0.58f, 3.8f, 10, wallStone);
                AddCylinder(ctx, bPos + new Vector3(0, 1.95f, 0), 0.72f, 0.72f, 0.22f, 10, trimGold);
                AddCone(ctx, bPos + new Vector3(0, 2.15f, 0), 0.78f, 1.8f, 10, turretRoof);
            }

            // 5. Oldingi Fasad Arkali Kirish Portali (Royal Arched Entrance)
            Vector3 frontGate = new Vector3(0, 1.0f, 1.45f);
            AddBox(ctx, frontGate, new Vector3(1.6f, 1.5f, 0.45f), wallStone);
            AddBox(ctx, frontGate + new Vector3(0, 0.8f, 0), new Vector3(1.75f, 0.15f, 0.52f), trimGold);
            AddBox(ctx, frontGate + new Vector3(0, -0.2f, 0.22f), new Vector3(0.85f, 1.1f, 0.10f), windowDark);

            // 6. Fasad oynalari qatori
            for (int l = 0; l < 2; l++)
            {
                float ly = 1.3f + l * 0.85f;
                AddBox(ctx, new Vector3(-0.9f, ly, 1.42f), new Vector3(0.35f, 0.55f, 0.06f), windowDark);
                AddBox(ctx, new Vector3( 0.9f, ly, 1.42f), new Vector3(0.35f, 0.55f, 0.06f), windowDark);
            }

            return ctx.ToMesh("Mesh_LargeImperialCastle");
        }
    }
}
