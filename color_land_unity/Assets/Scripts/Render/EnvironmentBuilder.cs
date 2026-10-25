using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — Boyitilgan Tabiat va Atrof-Muhit Qurg'ichi (EnvironmentBuilder).
    /// Blender 4.2 da yasalgan yuqori sifatli Stylized FBX modellarni
    /// (qorli tog'lar, mayoq / lighthouse, yog'och ko'priklar, qoyalar, archa va dumaloq daraxtlar)
    /// to'liq o'z materiallari va ranglari bilan dunyoga joylashtiradi.
    /// </summary>
    public static class EnvironmentBuilder
    {
        public static GameObject LoadModelPrefab(string modelName)
        {
#if UNITY_EDITOR
            var editorGo = UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>($"Assets/Models/{modelName}.fbx");
            if (editorGo != null) return editorGo;
            editorGo = UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>($"Assets/Resources/Models/{modelName}.fbx");
            if (editorGo != null) return editorGo;
#endif
            var go = Resources.Load<GameObject>($"Models/{modelName}");
            if (go != null) return go;
            Debug.LogError($"[EnvironmentBuilder] Failed to load model: {modelName}!");
            return null;
        }

        public static void BuildRichEnvironment(GameObject envRoot)
        {
            var mntPrefab = LoadModelPrefab("mountain_snowy");
            var bridgePrefab = LoadModelPrefab("bridge_wooden");
            var rockPrefab = LoadModelPrefab("rock_stylized");
            var pinePrefab = LoadModelPrefab("tree_stylized_pine");
            var roundPrefab = LoadModelPrefab("tree_stylized_round");
            var lightPrefab = LoadModelPrefab("lighthouse");

            // ==============================================================================
            // 1. SOXIL BO'YIDAGI 3D MAYOQ (Scenic Coastal Lighthouse on Cliff for Main Menu)
            // ==============================================================================
            if (lightPrefab != null)
            {
                var lightObj = new GameObject("CoastalLighthouse");
                lightObj.transform.SetParent(envRoot.transform, false);
                // Positioned on the picturesque promontory overlooking the azure bay
                lightObj.transform.position = new Vector3(5.5f, 0.2f, -6.5f);
                var inst = Object.Instantiate(lightPrefab, lightObj.transform, false);
                inst.transform.localScale = Vector3.one * 1.75f;
                inst.transform.rotation = Quaternion.Euler(0, 35.0f, 0);

                // Rocky cliff base for lighthouse
                if (rockPrefab != null)
                {
                    var cliffObj = Object.Instantiate(rockPrefab, lightObj.transform, false);
                    cliffObj.transform.localPosition = new Vector3(0, -0.1f, 0);
                    cliffObj.transform.localScale = new Vector3(3.5f, 1.2f, 3.5f);
                }
            }

            // ==============================================================================
            // 2. UZOQDAGI QORLI CHO'QQILI TOG' TIZMALARI (Snowy Alpine Mountain Ranges)
            // ==============================================================================
            Vector3[] mountainPositions = new Vector3[]
            {
                new Vector3(-68, 0, 48),  new Vector3(-58, 0, 68),  new Vector3(-42, 0, 72),
                new Vector3(-18, 0, 74),  new Vector3(18, 0, 74),   new Vector3(45, 0, 70),
                new Vector3(65, 0, 52),   new Vector3(72, 0, 22),   new Vector3(70, 0, -22),
                new Vector3(64, 0, -55),  new Vector3(-65, 0, -52), new Vector3(-72, 0, 0),
                new Vector3(-35, 0, 65),  new Vector3(0, 0, 75),    new Vector3(32, 0, 72)
            };

            for (int i = 0; i < mountainPositions.Length; i++)
            {
                var mntObj = new GameObject($"Mountain_{i}");
                mntObj.transform.SetParent(envRoot.transform, false);
                mntObj.transform.position = mountainPositions[i];

                float scaleY = Random.Range(2.0f, 2.9f);
                float scaleXZ = Random.Range(2.0f, 2.8f);

                if (mntPrefab != null)
                {
                    var inst = Object.Instantiate(mntPrefab, mntObj.transform, false);
                    inst.transform.localScale = new Vector3(scaleXZ, scaleY, scaleXZ);
                    inst.transform.rotation = Quaternion.Euler(0, Random.Range(0, 360), 0);
                }
            }

            // ==============================================================================
            // 3. YOG'OCH KAMON KO'PRIKLAR (Arched Wooden Bridges over Water)
            // ==============================================================================
            Vector3[] bridgePositions = new Vector3[]
            {
                new Vector3(1.2f, 0.25f, 12.2f),
                new Vector3(8.5f, 0.25f, 15.0f)
            };

            for (int b = 0; b < bridgePositions.Length; b++)
            {
                var bridgeRoot = new GameObject($"WoodenBridge_{b}");
                bridgeRoot.transform.SetParent(envRoot.transform, false);
                bridgeRoot.transform.position = bridgePositions[b];
                bridgeRoot.transform.rotation = Quaternion.Euler(0, b == 0 ? 46.0f : -25.0f, 0);

                if (bridgePrefab != null)
                {
                    var inst = Object.Instantiate(bridgePrefab, bridgeRoot.transform, false);
                    inst.transform.localScale = Vector3.one * 1.25f;
                }
            }

            // ==============================================================================
            // 4. QIRQOQ VA QOYALI OROLCHALAR (Faceted Stylized Boulders)
            // ==============================================================================
            Vector3[] rockPositions = new Vector3[]
            {
                // G'arbiy sohil va ko'rfaz orolchalari
                new Vector3(-18, 0, -12), new Vector3(-19, 0, -2), new Vector3(-16, 0, -7),
                new Vector3(-18, 0, 8),   new Vector3(-16, 0, 14),  new Vector3(-15, 0, 2),
                new Vector3(-20, 0, 4),   new Vector3(-17, 0, -15), new Vector3(-14, 0, -18),
                // Daryo va ko'prik atrofi
                new Vector3(1.2f, 0, 14.5f), new Vector3(4.2f, 0, 17.0f), new Vector3(8.5f, 0, 14.5f),
                new Vector3(0.5f, 0, 18.0f), new Vector3(6.5f, 0, 19.5f),
                // Janubiy ko'rfaz va Dubay qoyalari
                new Vector3(13, 0, -14),  new Vector3(15, 0, -8),   new Vector3(9, 0, -16),
                new Vector3(2, 0, -14),   new Vector3(-4, 0, -15),  new Vector3(5, 0, -18),
                // Suvdagi orolcha toshlari
                new Vector3(-12, 0, -16), new Vector3(-8, 0, -18), new Vector3(-15, 0, -8)
            };

            for (int r = 0; r < rockPositions.Length; r++)
            {
                var rockObj = new GameObject($"Rock_{r}");
                rockObj.transform.SetParent(envRoot.transform, false);
                rockObj.transform.position = rockPositions[r];

                float s = Random.Range(1.1f, 1.8f);
                if (rockPrefab != null)
                {
                    var inst = Object.Instantiate(rockPrefab, rockObj.transform, false);
                    inst.transform.localScale = new Vector3(s, s * 0.75f, s * 0.95f);
                    inst.transform.rotation = Quaternion.Euler(Random.Range(5, 20), Random.Range(0, 360), Random.Range(0, 15));
                }
            }

            // ==============================================================================
            // 5. QALIN MULTFILM DARAХTZORLAR (Blender Stylized Pine & Round Trees - 100+ Trees)
            // ==============================================================================
            Vector3[] treePositions = new Vector3[]
            {
                // A. Berlin [DE] orqasidagi qalin o'rmon va archazorlar
                new Vector3(-6.5f, 0, 19.5f), new Vector3(-2.0f, 0, 19.5f), new Vector3(-5.5f, 0, 21.0f),
                new Vector3(-1.0f, 0, 22.5f), new Vector3(-10.5f, 0, 16.0f), new Vector3(-8.5f, 0, 19.0f),
                new Vector3(-4.0f, 0, 23.0f), new Vector3(0.5f, 0, 21.0f),  new Vector3(-9.5f, 0, 13.5f),
                new Vector3(-11.0f, 0, 18.5f), new Vector3(-7.0f, 0, 23.5f), new Vector3(-1.5f, 0, 24.5f),

                // B. Daryo va yog'och ko'prik bo'yidagi daraxtlar
                new Vector3(1.2f, 0, 16.8f),  new Vector3(5.5f, 0, 17.5f),  new Vector3(3.8f, 0, 13.8f),
                new Vector3(7.2f, 0, 16.0f),  new Vector3(8.5f, 0, 18.5f),  new Vector3(2.5f, 0, 19.5f),
                new Vector3(4.8f, 0, 20.5f),  new Vector3(10.0f, 0, 16.5f), new Vector3(0.0f, 0, 14.5f),

                // C. Berlin va Samarqand oralig'idagi yam-yashil o'rmon (Markaziy to'qay)
                new Vector3(-6.0f, 0, 11.5f), new Vector3(-4.5f, 0, 9.0f),   new Vector3(-7.5f, 0, 7.5f),
                new Vector3(-3.0f, 0, 6.5f),  new Vector3(-5.0f, 0, 4.5f),   new Vector3(-7.0f, 0, 3.0f),
                new Vector3(-2.5f, 0, 11.0f), new Vector3(-4.0f, 0, 13.5f), new Vector3(-8.5f, 0, 10.0f),
                new Vector3(-5.5f, 0, 1.5f),  new Vector3(-3.5f, 0, 2.5f),   new Vector3(-6.5f, 0, 5.5f),

                // D. Samarqand [UZ] atrofidagi yam-yashil daraxtlar
                new Vector3(-12.5f, 0, 2.5f), new Vector3(-11.0f, 0, 5.5f), new Vector3(-9.0f, 0, -2.5f),
                new Vector3(-13.0f, 0, -1.0f), new Vector3(-8.0f, 0, 3.5f),  new Vector3(-10.5f, 0, 7.5f),
                new Vector3(-13.5f, 0, 4.0f), new Vector3(-7.5f, 0, -1.5f), new Vector3(-11.5f, 0, -3.5f),

                // E. Toshkent [UZ] moviy suv saroyi atrofidagi daraxtlar
                new Vector3(12.5f, 0, 7.5f),  new Vector3(11.0f, 0, 10.5f), new Vector3(8.5f, 0, 11.5f),
                new Vector3(13.0f, 0, 4.0f),  new Vector3(7.5f, 0, 8.5f),   new Vector3(14.0f, 0, 9.0f),
                new Vector3(9.5f, 0, 4.0f),   new Vector3(13.5f, 0, 12.0f), new Vector3(6.5f, 0, 11.0f),

                // F. Toshkent va Dubay oralig'idagi archazor
                new Vector3(5.5f, 0, 2.0f),   new Vector3(7.0f, 0, 0.0f),   new Vector3(4.5f, 0, -2.5f),
                new Vector3(6.0f, 0, -5.0f),  new Vector3(8.5f, 0, -3.0f),  new Vector3(3.0f, 0, -1.0f),
                new Vector3(5.0f, 0, -7.5f),  new Vector3(7.5f, 0, -7.0f),  new Vector3(4.0f, 0, -4.5f),

                // G. Dubay [AE] oltin saroyi atrofidagi daraxtlar
                new Vector3(10.5f, 0, -10.5f), new Vector3(14.5f, 0, -12.5f), new Vector3(13.5f, 0, -8.0f),
                new Vector3(8.5f, 0, -14.0f),  new Vector3(15.5f, 0, -10.0f), new Vector3(11.5f, 0, -14.5f),
                new Vector3(16.0f, 0, -14.0f), new Vector3(9.5f, 0, -8.5f),   new Vector3(14.0f, 0, -6.5f),

                // H. G'arbiy sohil va ko'rfaz orolchalari bo'yidagi daraxtlar
                new Vector3(-18.0f, 0, -12.0f), new Vector3(-19.0f, 0, -2.0f), new Vector3(-16.5f, 0, -7.0f),
                new Vector3(-17.5f, 0, 8.0f),   new Vector3(-15.5f, 0, 13.0f), new Vector3(-19.5f, 0, 3.0f),
                new Vector3(-16.0f, 0, 3.0f),   new Vector3(-18.5f, 0, -8.0f), new Vector3(-14.5f, 0, -12.0f),

                // I. Janubiy sohil bo'yidagi qirg'oq daraxtlari va mayoq atrofi
                new Vector3(1.5f, 0, -11.0f),  new Vector3(-2.0f, 0, -12.5f), new Vector3(4.0f, 0, -12.0f),
                new Vector3(6.5f, 0, -13.5f),  new Vector3(-1.0f, 0, -9.5f),  new Vector3(2.5f, 0, -8.5f),
                new Vector3(-6.5f, 0, -10.5f), new Vector3(-10.5f, 0, -11.5f), new Vector3(-7.5f, 0, -14.0f)
            };

            for (int t = 0; t < treePositions.Length; t++)
            {
                var treeObj = new GameObject($"Tree_{t}");
                treeObj.transform.SetParent(envRoot.transform, false);
                treeObj.transform.position = treePositions[t];

                bool isPine = (t % 3 != 0); // 2/3 archa, 1/3 yumaloq bargli daraxt
                var prefab = isPine ? pinePrefab : roundPrefab;

                if (prefab != null)
                {
                    var inst = Object.Instantiate(prefab, treeObj.transform, false);
                    float s = Random.Range(1.10f, 1.55f);
                    inst.transform.localScale = Vector3.one * s;
                    inst.transform.rotation = Quaternion.Euler(0, Random.Range(0, 360), 0);
                }
            }
        }
    }
}
