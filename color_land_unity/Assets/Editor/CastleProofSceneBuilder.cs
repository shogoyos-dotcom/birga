#if UNITY_EDITOR
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.SceneManagement;

namespace ColorLand.Editor
{
    public static class CastleProofSceneBuilder
    {
        private static readonly string ArtifactDir = @"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2";

        [MenuItem("ColorLand/Build Castle Quality Demo Scene")]
        public static void BuildAndCapture()
        {
            Debug.Log("[CastleProofSceneBuilder] Starting Castle Quality Demonstration Scene build...");

            // 1. Force import of assets
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);

            string fbxPath = "Assets/Models/fantasy_castle_proof.fbx";
            string texPath = "Assets/Textures/castle_variation_a.png";
            string matPath = "Assets/Materials/M_CastleProofDemo.mat";
            string scenePath = "Assets/Scenes/CastleQualityDemo.unity";

            // Configure Texture
            var texImporter = AssetImporter.GetAtPath(texPath) as TextureImporter;
            if (texImporter != null)
            {
                texImporter.textureType = TextureImporterType.Default;
                texImporter.sRGBTexture = true;
                texImporter.filterMode = FilterMode.Bilinear;
                texImporter.wrapMode = TextureWrapMode.Clamp;
                texImporter.maxTextureSize = 1024;
                texImporter.SaveAndReimport();
            }

            var tex = AssetDatabase.LoadAssetAtPath<Texture2D>(texPath);

            // Shader selection (URP or CartoonLit or Standard)
            var shader = Shader.Find("ColorLand/CartoonLit")
                      ?? Shader.Find("Universal Render Pipeline/Lit")
                      ?? Shader.Find("Standard")
                      ?? Shader.Find("Mobile/Diffuse");

            var mat = AssetDatabase.LoadAssetAtPath<Material>(matPath);
            if (mat == null)
            {
                mat = new Material(shader);
                AssetDatabase.CreateAsset(mat, matPath);
            }
            else
            {
                mat.shader = shader;
            }

            mat.name = "M_CastleProofDemo";
            if (tex != null)
            {
                mat.mainTexture = tex;
                if (mat.HasProperty("_BaseMap")) mat.SetTexture("_BaseMap", tex);
            }
            mat.color = Color.white;
            if (mat.HasProperty("_BaseColor")) mat.SetColor("_BaseColor", Color.white);
            if (mat.HasProperty("_Smoothness")) mat.SetFloat("_Smoothness", 0.35f);
            EditorUtility.SetDirty(mat);
            AssetDatabase.SaveAssets();

            // 2. Create separate scene
            var newScene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // 3. Environment & Lighting
            var lightObj = new GameObject("Directional Light");
            var light = lightObj.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1.0f, 0.95f, 0.88f);
            light.intensity = 1.35f;
            light.shadows = LightShadows.Soft;
            light.shadowResolution = UnityEngine.Rendering.LightShadowResolution.VeryHigh;
            lightObj.transform.rotation = Quaternion.Euler(48f, 25f, 0f);

            // Ambient
            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.65f, 0.78f, 0.95f);
            RenderSettings.ambientEquatorColor = new Color(0.45f, 0.52f, 0.60f);
            RenderSettings.ambientGroundColor = new Color(0.20f, 0.28f, 0.18f);

            // 4. Ground Pedestal (Stylized Island)
            var groundObj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            groundObj.name = "GroundPedestal";
            groundObj.transform.position = new Vector3(0, -0.25f, -0.5f);
            groundObj.transform.localScale = new Vector3(14f, 0.5f, 14f);

            var groundMat = new Material(shader) { name = "M_DemoGrass" };
            groundMat.color = new Color(0.25f, 0.55f, 0.22f); // Vibrant stylized grass
            if (groundMat.HasProperty("_BaseColor")) groundMat.SetColor("_BaseColor", new Color(0.25f, 0.55f, 0.22f));
            groundObj.GetComponent<MeshRenderer>().sharedMaterial = groundMat;

            // 5. Castle Model Instance
            var castlePrefab = AssetDatabase.LoadAssetAtPath<GameObject>(fbxPath);
            if (castlePrefab != null)
            {
                var castleInst = (GameObject)PrefabUtility.InstantiatePrefab(castlePrefab);
                castleInst.name = "FantasyCastle_Proof";
                castleInst.transform.position = Vector3.zero;
                castleInst.transform.rotation = Quaternion.identity;
                castleInst.transform.localScale = Vector3.one * 1.0f;

                // Assign material to all renderers
                foreach (var r in castleInst.GetComponentsInChildren<MeshRenderer>())
                {
                    r.sharedMaterial = mat;
                }
            }
            else
            {
                Debug.LogError($"[CastleProofSceneBuilder] Failed to load castle prefab at: {fbxPath}");
            }

            // 6. Camera Setup
            var camObj = new GameObject("Main Camera");
            var cam = camObj.AddComponent<Camera>();
            camObj.tag = "MainCamera";
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.14f, 0.18f, 0.24f); // Rich dark slate studio background
            cam.fieldOfView = 42f;
            cam.nearClipPlane = 0.3f;
            cam.farClipPlane = 100f;

            camObj.transform.position = new Vector3(11.5f, 9.5f, -12.5f);
            camObj.transform.LookAt(new Vector3(0, 2.8f, -0.5f));

            // 7. Save Scene
            string sceneDir = Path.GetDirectoryName(scenePath);
            if (!Directory.Exists(sceneDir)) Directory.CreateDirectory(sceneDir);
            EditorSceneManager.SaveScene(newScene, scenePath);
            Debug.Log($"[CastleProofSceneBuilder] Saved demonstration scene to: {scenePath}");

            // 8. Capture Real High-Res Screenshot
            int width = 1080;
            int height = 1080;
            var rt = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
            cam.targetTexture = rt;
            cam.Render();

            RenderTexture.active = rt;
            var tex2D = new Texture2D(width, height, TextureFormat.RGB24, false);
            tex2D.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            tex2D.Apply();
            cam.targetTexture = null;
            RenderTexture.active = null;
            Object.DestroyImmediate(rt);

            byte[] bytes = tex2D.EncodeToPNG();
            Object.DestroyImmediate(tex2D);

            if (!Directory.Exists(ArtifactDir)) Directory.CreateDirectory(ArtifactDir);
            string outScreenshot = Path.Combine(ArtifactDir, "unity_castle_quality_demo.png");
            File.WriteAllBytes(outScreenshot, bytes);
            Debug.Log($"[CastleProofSceneBuilder] Saved Unity screenshot to: {outScreenshot} ({bytes.Length} bytes)");
        }
    }
}
#endif
