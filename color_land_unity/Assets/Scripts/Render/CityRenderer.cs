using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.Logic;
using ColorLand.App;

namespace ColorLand.Render
{
    /// <summary>
    /// Shaharlarning 3D vizual tasviri (CityRenderer).
    /// Kichik, O'rta va Katta shaharlar uchun haqiqiy past poligonli 3D multfilm
    /// modellarini (CityMeshBuilder) chizadi, poytaxt shtilini va ko'rinarli
    /// 3D nom/bayroq ko'rsatkichini joylashtiradi.
    /// </summary>
    public class CityRenderer : MonoBehaviour
    {
        private readonly List<GameObject> _cityObjects = new List<GameObject>();
        private CitySystem _citySystem;
        private Material _cityBaseMaterial;
        private Shader _litShader;

        public void Initialize(CitySystem citySystem)
        {
            _citySystem = citySystem;
            CreateMaterials();
            SpawnCityMeshes();

            _citySystem.OnCityCaptured += OnCityCaptured;
        }

        private void OnDestroy()
        {
            if (_citySystem != null)
            {
                _citySystem.OnCityCaptured -= OnCityCaptured;
            }
            if (_cityBaseMaterial != null) Destroy(_cityBaseMaterial);
        }

        private void CreateMaterials()
        {
            _litShader = Shader.Find("ColorLand/CartoonLit")
                      ?? Shader.Find("Universal Render Pipeline/Lit")
                      ?? Shader.Find("Standard")
                      ?? Shader.Find("Mobile/Diffuse");

            _cityBaseMaterial = new Material(_litShader)
            {
                color = Color.white,
                name = "M_CityBase"
            };
        }

        private GameObject LoadCityPrefab(string modelName)
        {
#if UNITY_EDITOR
            var editorGo = UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>($"Assets/Models/{modelName}.fbx");
            if (editorGo != null) return editorGo;
            editorGo = UnityEditor.AssetDatabase.LoadAssetAtPath<GameObject>($"Assets/Resources/Models/{modelName}.fbx");
            if (editorGo != null) return editorGo;
#endif
            var go = Resources.Load<GameObject>($"Models/{modelName}");
            if (go != null) return go;
            Debug.LogError($"[CityRenderer] Failed to load city model: {modelName}!");
            return null;
        }

        private void SpawnCityMeshes()
        {
            foreach (var go in _cityObjects)
            {
                if (go != null) Destroy(go);
            }
            _cityObjects.Clear();

            if (_citySystem == null) return;

            Font font = Resources.Load<Font>("Fonts/Fredoka")
                     ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf")
                     ?? Resources.GetBuiltinResource<Font>("Arial.ttf");

            foreach (var city in _citySystem.Cities)
            {
                var cityRoot = new GameObject($"City_{city.Name}");
                cityRoot.transform.SetParent(transform);
                cityRoot.transform.position = city.WorldPos;

                float labelHeight = 8.5f;
                float cityScale = 1.7f;
                string modelName = "castle_small";

                if (city.Name.Equals("Berlin", System.StringComparison.OrdinalIgnoreCase))
                {
                    modelName = "castle_berlin";
                    cityScale = 1.75f;
                    labelHeight = 11.2f;
                }
                else if (city.Name.Equals("Tashkent", System.StringComparison.OrdinalIgnoreCase))
                {
                    modelName = "castle_tashkent";
                    cityScale = 1.85f;
                    labelHeight = 12.0f;
                }
                else if (city.Name.Equals("Samarkand", System.StringComparison.OrdinalIgnoreCase))
                {
                    modelName = "castle_samarkand";
                    cityScale = 1.65f;
                    labelHeight = 10.6f;
                }
                else if (city.Name.Equals("Dubai", System.StringComparison.OrdinalIgnoreCase))
                {
                    modelName = "castle_dubai";
                    cityScale = 1.70f;
                    labelHeight = 11.4f;
                }
                else
                {
                    switch (city.Category)
                    {
                        case CityCategory.Small:
                            modelName = "castle_small";
                            cityScale = 1.45f;
                            labelHeight = 8.8f;
                            break;
                        case CityCategory.Medium:
                            modelName = "castle_medium";
                            cityScale = 1.65f;
                            labelHeight = 10.2f;
                            break;
                        case CityCategory.Large:
                        default:
                            modelName = "castle_large";
                            cityScale = 1.80f;
                            labelHeight = 11.8f;
                            break;
                    }
                }

                // 1. 3D Model binosi (Blender FBX prefab to'liq materiallari bilan)
                var prefab = LoadCityPrefab(modelName);
                if (prefab != null)
                {
                    var modelObj = Instantiate(prefab, cityRoot.transform, false);
                    modelObj.name = "CityModel";
                    modelObj.transform.localScale = Vector3.one * cityScale;
                    modelObj.transform.localPosition = Vector3.zero;
                }

                // 2. Shahar poydevorida bayroq va shtil (3D modellarda o'z bayrog'i va shpillari mavjud)
                // SpawnCityFlag olib tashlandi, chunki FBX modellarning o'zida go'zal bayroq va shpirlar bor

                // 3. Trigger kollayder (o'yinchi va botlar shahar maydoniga kirganda aniqlash)
                var boxCol = cityRoot.AddComponent<BoxCollider>();
                boxCol.center = new Vector3(0, labelHeight * 0.4f, 0);
                boxCol.size = new Vector3(3.6f * cityScale, labelHeight * 0.8f, 3.6f * cityScale);
                boxCol.isTrigger = true;

                // 4. Shahar nomini ko'rsatuvchi 3D Billboard Canvas
                CreateCityLabel(cityRoot.transform, city, labelHeight, font);

                _cityObjects.Add(cityRoot);
            }
        }

        private void SpawnCityFlag(Transform parent, CityData city, float scale)
        {
            var flagRoot = new GameObject("CityFlag");
            flagRoot.transform.SetParent(parent, false);
            // Stand proudly at the front-left plaza corner without clipping central structures
            flagRoot.transform.localPosition = new Vector3(-1.35f * scale, 0.2f, -1.25f * scale);

            // Ustun
            var pole = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            pole.name = "Pole";
            pole.transform.SetParent(flagRoot.transform, false);
            float poleH = city.Category == CityCategory.Large ? 3.2f : (city.Category == CityCategory.Medium ? 2.5f : 1.9f);
            pole.transform.localPosition = new Vector3(0, poleH * 0.5f, 0);
            pole.transform.localScale = new Vector3(0.06f, poleH * 0.5f, 0.06f);
            var poleMat = new Material(_litShader) { color = new Color(0.85f, 0.88f, 0.92f), name = "M_Pole" };
            pole.GetComponent<Renderer>().sharedMaterial = poleMat;
            var pCol = pole.GetComponent<Collider>();
            if (pCol != null) DestroyImmediate(pCol);

            // Cho'qqi oltin shar
            var finial = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            finial.name = "Finial";
            finial.transform.SetParent(flagRoot.transform, false);
            finial.transform.localPosition = new Vector3(0, poleH + 0.1f, 0);
            finial.transform.localScale = Vector3.one * 0.22f;
            var finMat = new Material(_litShader) { color = new Color(0.96f, 0.75f, 0.12f), name = "M_Finial" };
            finial.GetComponent<Renderer>().sharedMaterial = finMat;
            var fCol = finial.GetComponent<Collider>();
            if (fCol != null) DestroyImmediate(fCol);

            // Bayroq matosi
            var flagQuad = GameObject.CreatePrimitive(PrimitiveType.Quad);
            flagQuad.name = "Cloth";
            flagQuad.transform.SetParent(flagRoot.transform, false);
            float flagW = 1.0f * scale;
            float flagH = 0.65f * scale;
            flagQuad.transform.localPosition = new Vector3(flagW * 0.5f + 0.04f, poleH - flagH * 0.5f, 0);
            flagQuad.transform.localRotation = Quaternion.Euler(0, 90f, 0);
            flagQuad.transform.localScale = new Vector3(flagW, flagH, 1.0f);

            Sprite flagSprite = Resources.Load<Sprite>($"Flags/png/{city.CountryCode.ToUpperInvariant()}");
            var clothMat = new Material(_litShader) { name = $"M_CityFlag_{city.CountryCode}" };
            if (flagSprite != null)
            {
                clothMat.mainTexture = flagSprite.texture;
                clothMat.color = Color.white;
            }
            else
            {
                clothMat.color = new Color(0.9f, 0.2f, 0.2f);
            }
            flagQuad.GetComponent<Renderer>().sharedMaterial = clothMat;
            var qCol = flagQuad.GetComponent<Collider>();
            if (qCol != null) DestroyImmediate(qCol);
        }

        private void CreateCityLabel(Transform parent, CityData city, float height, Font font)
        {
            var canvasObj = new GameObject("CityLabelCanvas");
            canvasObj.transform.SetParent(parent);
            canvasObj.transform.localPosition = new Vector3(0, height, 0);

            var canvas = canvasObj.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.WorldSpace;
            var rt = canvasObj.GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(280, 52);
            rt.localScale = Vector3.one * 0.020f;

            // Har doim kameraga qarab turishi uchun
            var lookAt = canvasObj.AddComponent<BillboardLookAtCamera>();

            // Chiroyli to'q ko'k kapsula fon (Pill Navy)
            Sprite pillSprite = Resources.Load<Sprite>("UI/pill_navy") ?? Resources.Load<Sprite>("UI/panel_dialog");
            var bgObj = new GameObject("Bg", typeof(RectTransform), typeof(Image));
            bgObj.transform.SetParent(canvasObj.transform, false);
            var bgRt = bgObj.GetComponent<RectTransform>();
            bgRt.anchorMin = Vector2.zero;
            bgRt.anchorMax = Vector2.one;
            bgRt.sizeDelta = Vector2.zero;
            var bgImg = bgObj.GetComponent<Image>();
            if (pillSprite != null)
            {
                bgImg.sprite = pillSprite;
                bgImg.type = Image.Type.Sliced;
            }
            bgImg.color = Color.white;

            // Chap tomondagi bayroq nishoni (Flag Icon)
            string codeUpper = city.CountryCode.ToUpperInvariant();
            Sprite flagSprite = Resources.Load<Sprite>($"Flags/png/{codeUpper}");
            if (flagSprite == null)
            {
                Texture2D flagTex = Resources.Load<Texture2D>($"Flags/png/{codeUpper}");
                if (flagTex != null)
                {
                    flagSprite = Sprite.Create(flagTex, new Rect(0, 0, flagTex.width, flagTex.height), new Vector2(0.5f, 0.5f));
                }
            }

            if (flagSprite != null)
            {
                var flagImgObj = new GameObject("FlagIcon", typeof(RectTransform), typeof(Image));
                flagImgObj.transform.SetParent(canvasObj.transform, false);
                var fRt = flagImgObj.GetComponent<RectTransform>();
                fRt.anchorMin = new Vector2(0, 0.5f);
                fRt.anchorMax = new Vector2(0, 0.5f);
                fRt.pivot = new Vector2(0, 0.5f);
                fRt.anchoredPosition = new Vector2(10, 0);
                fRt.sizeDelta = new Vector2(36, 26);
                var fImg = flagImgObj.GetComponent<Image>();
                fImg.sprite = flagSprite;
            }

            // Matn: Shahar nomi va oltin yulduz
            var txtObj = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtObj.transform.SetParent(canvasObj.transform, false);
            var txtRt = txtObj.GetComponent<RectTransform>();
            txtRt.anchorMin = Vector2.zero;
            txtRt.anchorMax = Vector2.one;
            txtRt.offsetMin = new Vector2(54, 0);
            txtRt.offsetMax = new Vector2(-10, 0);
            var txt = txtObj.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 20;
            txt.horizontalOverflow = HorizontalWrapMode.Overflow;
            txt.verticalOverflow = VerticalWrapMode.Overflow;
            txt.alignment = TextAnchor.MiddleLeft;
            txt.color = Color.white;
            txt.fontStyle = FontStyle.Bold;

            string capStar = city.IsCapital ? " ★" : "";
            txt.text = $"{city.LocalizedName} [{city.CountryCode}]{capStar}";
        }

        private void OnCityCaptured(CityData city, byte capturerId, int reward)
        {
            int index = city.Id - 1;
            if (index >= 0 && index < _cityObjects.Count)
            {
                var root = _cityObjects[index];
                if (root == null) return;

                Color c = capturerId == 1 ? new Color(0.15f, 0.65f, 1.0f) : UnityEngine.Random.ColorHSV(0f, 1f, 0.6f, 0.9f, 0.7f, 1.0f);

                // Egallangan shahar nishoni (Aura halqasi)
                var auraObj = root.transform.Find("CapturedAura");
                if (auraObj == null)
                {
                    var aura = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                    aura.name = "CapturedAura";
                    aura.transform.SetParent(root.transform, false);
                    aura.transform.localPosition = new Vector3(0, 0.05f, 0);
                    aura.transform.localScale = new Vector3(4.2f, 0.06f, 4.2f);
                    var aCol = aura.GetComponent<Collider>();
                    if (aCol != null) Destroy(aCol);

                    var auraMat = new Material(_litShader)
                    {
                        color = c,
                        name = $"M_CityAura_{capturerId}"
                    };
                    aura.GetComponent<Renderer>().sharedMaterial = auraMat;
                }
                else
                {
                    var r = auraObj.GetComponent<Renderer>();
                    if (r != null) r.material.color = c;
                }

                // Billboard yorlig'i rangini yangilash
                var txt = root.GetComponentInChildren<Text>();
                if (txt != null)
                {
                    txt.color = c;
                }
            }
        }
    }

    /// <summary>
    /// Matn yoki ikonkani har doim kameraga to'g'rilab turuvchi komponent.
    /// </summary>
    public class BillboardLookAtCamera : MonoBehaviour
    {
        private Transform _camTransform;

        public void AlignWithCamera(Camera cam = null)
        {
            if (cam == null) cam = Camera.main;
            if (cam != null)
            {
                transform.rotation = cam.transform.rotation;
            }
        }

        private void Start()
        {
            AlignWithCamera();
        }

        private void LateUpdate()
        {
            AlignWithCamera();
        }
    }
}
