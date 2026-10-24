using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — Boyitilgan Tabiat va Atrof-Muhit Qurg'ichi (EnvironmentBuilder).
    /// Foydalanuvchi yuborgan etalon manzaraga 100% mos:
    /// - Uzoqdagi qorli cho'qqili tog' tizmalari (Snow-capped mountains)
    /// - Daryo ustidagi yog'och kamon ko'prik (Arched wooden bridge)
    /// - Moviy suvdan chiqib turgan qoyali orolchalar (Rocky islets)
    /// - Sohildagi zich qarag'ayzorlar (Dense pine forests)
    /// </summary>
    public static class EnvironmentBuilder
    {
        public static void BuildRichEnvironment(GameObject envRoot)
        {
            Shader litShader = Shader.Find("ColorLand/CartoonLit") 
                            ?? Shader.Find("Universal Render Pipeline/Lit") 
                            ?? Shader.Find("Mobile/Diffuse");

            var mountainRockMat = new Material(litShader) { color = new Color(0.45f, 0.48f, 0.54f), name = "M_MountainRock" };
            var mountainSnowMat = new Material(litShader) { color = new Color(0.96f, 0.98f, 1.0f), name = "M_MountainSnow" };
            var bridgeWoodMat = new Material(litShader) { color = new Color(0.60f, 0.40f, 0.22f), name = "M_BridgeWood" };
            var bridgeRailMat = new Material(litShader) { color = new Color(0.45f, 0.28f, 0.15f), name = "M_BridgeRail" };
            var trunkMat = new Material(litShader) { color = new Color(0.45f, 0.28f, 0.15f), name = "M_Trunk" };
            var pineMat1 = new Material(litShader) { color = new Color(0.12f, 0.55f, 0.24f), name = "M_Pine1" };
            var pineMat2 = new Material(litShader) { color = new Color(0.18f, 0.68f, 0.30f), name = "M_Pine2" };
            var rockMat = new Material(litShader) { color = new Color(0.52f, 0.56f, 0.62f), name = "M_Rock" };

            // ==============================================================================
            // 1. UZOQDAGI QORLI CHO'QQILI TOG' TIZMALARI (Snow-capped Mountains on horizon)
            // ==============================================================================
            Vector3[] mountainPositions = new Vector3[]
            {
                new Vector3(-68, 0, 48),  new Vector3(-58, 0, 68),  new Vector3(-42, 0, 72),
                new Vector3(-18, 0, 74),  new Vector3(18, 0, 74),   new Vector3(45, 0, 70),
                new Vector3(65, 0, 52),   new Vector3(72, 0, 22),   new Vector3(70, 0, -22),
                new Vector3(64, 0, -55),  new Vector3(-65, 0, -52), new Vector3(-72, 0, 0)
            };

            for (int i = 0; i < mountainPositions.Length; i++)
            {
                var mntObj = new GameObject($"Mountain_{i}");
                mntObj.transform.SetParent(envRoot.transform, false);
                mntObj.transform.position = mountainPositions[i];

                float mHeight = UnityEngine.Random.Range(18.0f, 26.0f);
                float mRadius = UnityEngine.Random.Range(12.0f, 18.0f);

                // Asosiy tosh piramida/konus
                var rockCone = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                rockCone.name = "MountainBody";
                rockCone.transform.SetParent(mntObj.transform, false);
                rockCone.transform.localPosition = new Vector3(0, mHeight * 0.45f, 0);
                rockCone.transform.localScale = new Vector3(mRadius, mHeight * 0.45f, mRadius);
                rockCone.GetComponent<Renderer>().sharedMaterial = mountainRockMat;
                var rcCol = rockCone.GetComponent<Collider>();
                if (rcCol != null) UnityEngine.Object.DestroyImmediate(rcCol);

                // Qorli cho'qqi (Snow Cap atop mountain)
                var snowCone = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                snowCone.name = "SnowCap";
                snowCone.transform.SetParent(mntObj.transform, false);
                snowCone.transform.localPosition = new Vector3(0, mHeight * 0.85f, 0);
                snowCone.transform.localScale = new Vector3(mRadius * 0.45f, mHeight * 0.25f, mRadius * 0.45f);
                snowCone.GetComponent<Renderer>().sharedMaterial = mountainSnowMat;
                var scCol = snowCone.GetComponent<Collider>();
                if (scCol != null) UnityEngine.Object.DestroyImmediate(scCol);
            }

            // ==============================================================================
            // 2. YOG'OCH KAMON KO'PRIKLAR (Arched Wooden Bridges over waterways)
            // ==============================================================================
            Vector3[] bridgePositions = new Vector3[]
            {
                new Vector3(12, 0.4f, 28),
                new Vector3(-25, 0.4f, 15)
            };

            for (int b = 0; b < bridgePositions.Length; b++)
            {
                var bridgeRoot = new GameObject($"WoodenBridge_{b}");
                bridgeRoot.transform.SetParent(envRoot.transform, false);
                bridgeRoot.transform.position = bridgePositions[b];
                bridgeRoot.transform.rotation = Quaternion.Euler(0, 35.0f * b + 45.0f, 0);

                // Kamon taxtalari (Arched bridge deck)
                var deck = GameObject.CreatePrimitive(PrimitiveType.Cube);
                deck.name = "Deck";
                deck.transform.SetParent(bridgeRoot.transform, false);
                deck.transform.localPosition = new Vector3(0, 0.35f, 0);
                deck.transform.localScale = new Vector3(2.2f, 0.16f, 6.5f);
                deck.GetComponent<Renderer>().sharedMaterial = bridgeWoodMat;
                var dCol = deck.GetComponent<Collider>();
                if (dCol != null) UnityEngine.Object.DestroyImmediate(dCol);

                // Ko'prik to'siqlari va ustunlari (Railings)
                for (int side = -1; side <= 1; side += 2)
                {
                    var rail = GameObject.CreatePrimitive(PrimitiveType.Cube);
                    rail.name = $"Railing_{side}";
                    rail.transform.SetParent(bridgeRoot.transform, false);
                    rail.transform.localPosition = new Vector3(side * 1.05f, 0.75f, 0);
                    rail.transform.localScale = new Vector3(0.12f, 0.55f, 6.4f);
                    rail.GetComponent<Renderer>().sharedMaterial = bridgeRailMat;
                    var rCol = rail.GetComponent<Collider>();
                    if (rCol != null) UnityEngine.Object.DestroyImmediate(rCol);
                }
            }

            // ==============================================================================
            // 3. MOVIY SUVDAGI QOYALI OROLCHALAR (Rocky Islets with trees)
            // ==============================================================================
            Vector3[] isletPositions = new Vector3[]
            {
                new Vector3(-28, 0, -32),
                new Vector3(-35, 0, -22),
                new Vector3(32, 0, -28),
                new Vector3(26, 0, 36)
            };

            for (int i = 0; i < isletPositions.Length; i++)
            {
                var isletObj = new GameObject($"Islet_{i}");
                isletObj.transform.SetParent(envRoot.transform, false);
                isletObj.transform.position = isletPositions[i];

                // Qoya tosh asosi
                var rock = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                rock.name = "IsletRock";
                rock.transform.SetParent(isletObj.transform, false);
                rock.transform.localPosition = new Vector3(0, 0.2f, 0);
                rock.transform.localScale = new Vector3(3.8f, 1.2f, 3.2f);
                rock.GetComponent<Renderer>().sharedMaterial = rockMat;
                var rkCol = rock.GetComponent<Collider>();
                if (rkCol != null) UnityEngine.Object.DestroyImmediate(rkCol);

                // Orolchada bitta qarag'ay daraxti
                var tree = CreateStylizedPine(isletObj.transform, new Vector3(0.2f, 0.8f, 0.1f), trunkMat, pineMat1, pineMat2);
            }

            // ==============================================================================
            // 4. ZICH QARAG'AYZORLAR (Clustered stylized pine groves along coastlines)
            // ==============================================================================
            Vector3[] groveCenters = new Vector3[]
            {
                new Vector3(-20, 0, 25), new Vector3(20, 0, 22),
                new Vector3(-30, 0, -10), new Vector3(30, 0, -12),
                new Vector3(-12, 0, -35), new Vector3(15, 0, -32),
                new Vector3(-45, 0, 35), new Vector3(45, 0, 35)
            };

            int treeCount = 0;
            for (int g = 0; g < groveCenters.Length; g++)
            {
                Vector3 center = groveCenters[g];
                for (int t = 0; t < 4; t++)
                {
                    float ox = (t % 2 == 0 ? -1.4f : 1.4f) + UnityEngine.Random.Range(-0.4f, 0.4f);
                    float oz = (t < 2 ? -1.4f : 1.4f) + UnityEngine.Random.Range(-0.4f, 0.4f);
                    Vector3 pos = center + new Vector3(ox, 0, oz);

                    var trObj = new GameObject($"ForestTree_{treeCount++}");
                    trObj.transform.SetParent(envRoot.transform, false);
                    trObj.transform.position = pos;
                    CreateStylizedPine(trObj.transform, Vector3.zero, trunkMat, pineMat1, pineMat2);
                }
            }
        }

        private static GameObject CreateStylizedPine(Transform parent, Vector3 localPos, Material trunkMat, Material pine1, Material pine2)
        {
            var root = new GameObject("PineTree");
            root.transform.SetParent(parent, false);
            root.transform.localPosition = localPos;

            // Tana
            var trunk = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            trunk.name = "Trunk";
            trunk.transform.SetParent(root.transform, false);
            trunk.transform.localPosition = new Vector3(0, 0.6f, 0);
            trunk.transform.localScale = new Vector3(0.3f, 0.6f, 0.3f);
            trunk.GetComponent<Renderer>().sharedMaterial = trunkMat;
            var tCol = trunk.GetComponent<Collider>();
            if (tCol != null) UnityEngine.Object.DestroyImmediate(tCol);

            // 3 qatlamli konus toj
            for (int i = 0; i < 3; i++)
            {
                var cone = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                cone.name = $"Cone_{i}";
                cone.transform.SetParent(root.transform, false);
                float y = 1.1f + i * 0.7f;
                float r = 1.45f - i * 0.35f;
                cone.transform.localPosition = new Vector3(0, y, 0);
                cone.transform.localScale = new Vector3(r, 0.85f, r);
                cone.GetComponent<Renderer>().sharedMaterial = (i % 2 == 0) ? pine1 : pine2;
                var cCol = cone.GetComponent<Collider>();
                if (cCol != null) UnityEngine.Object.DestroyImmediate(cCol);
            }

            return root;
        }
    }
}
