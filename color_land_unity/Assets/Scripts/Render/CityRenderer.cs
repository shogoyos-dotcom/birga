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

        private Mesh _smallMesh;
        private Mesh _mediumMesh;
        private Mesh _largeMesh;

        public void Initialize(CitySystem citySystem)
        {
            _citySystem = citySystem;
            CreateMaterials();
            BuildCachedMeshes();
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
            if (_smallMesh != null) Destroy(_smallMesh);
            if (_mediumMesh != null) Destroy(_mediumMesh);
            if (_largeMesh != null) Destroy(_largeMesh);
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

        private void BuildCachedMeshes()
        {
            _smallMesh = CityMeshBuilder.BuildSmallCityMesh();
            _mediumMesh = CityMeshBuilder.BuildMediumCityMesh();
            _largeMesh = CityMeshBuilder.BuildLargeCityMesh();
        }

        private void SpawnCityMeshes()
        {
            foreach (var go in _cityObjects)
            {
                if (go != null) Destroy(go);
            }
            _cityObjects.Clear();

            if (_citySystem == null) return;

            Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");

            foreach (var city in _citySystem.Cities)
            {
                var cityRoot = new GameObject($"City_{city.Name}");
                cityRoot.transform.SetParent(transform);
                cityRoot.transform.position = city.WorldPos;

                Mesh targetMesh;
                float labelHeight;
                float cityScale;

                switch (city.Category)
                {
                    case CityCategory.Small:
                        targetMesh = _smallMesh;
                        cityScale = 0.85f;
                        labelHeight = 2.8f;
                        break;
                    case CityCategory.Medium:
                        targetMesh = _mediumMesh;
                        cityScale = 0.95f;
                        labelHeight = 4.6f;
                        break;
                    case CityCategory.Large:
                    default:
                        targetMesh = _largeMesh;
                        cityScale = 1.05f;
                        labelHeight = 7.2f;
                        break;
                }

                // 1. 3D Model binosi
                var modelObj = new GameObject("CityModel");
                modelObj.transform.SetParent(cityRoot.transform, false);
                modelObj.transform.localScale = Vector3.one * cityScale;

                var mf = modelObj.AddComponent<MeshFilter>();
                mf.sharedMesh = targetMesh;

                var mr = modelObj.AddComponent<MeshRenderer>();
                mr.sharedMaterial = _cityBaseMaterial;

                // 2. Shahar poydevorida bayroq ustuni va milliy bayroq
                SpawnCityFlag(cityRoot.transform, city, cityScale);

                // 3. Trigger kollayder (o'yinchi va botlar shahar maydoniga kirganda aniqlash)
                var boxCol = cityRoot.AddComponent<BoxCollider>();
                boxCol.center = new Vector3(0, labelHeight * 0.4f, 0);
                boxCol.size = new Vector3(4.0f * cityScale, labelHeight * 0.8f, 4.0f * cityScale);
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
            flagRoot.transform.localPosition = new Vector3(0.1f * scale, 0.35f * scale, 0);

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
            if (pCol != null) Destroy(pCol);

            // Cho'qqi oltin shar
            var finial = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            finial.name = "Finial";
            finial.transform.SetParent(flagRoot.transform, false);
            finial.transform.localPosition = new Vector3(0, poleH + 0.1f, 0);
            finial.transform.localScale = Vector3.one * 0.22f;
            var finMat = new Material(_litShader) { color = new Color(0.96f, 0.75f, 0.12f), name = "M_Finial" };
            finial.GetComponent<Renderer>().sharedMaterial = finMat;
            var fCol = finial.GetComponent<Collider>();
            if (fCol != null) Destroy(fCol);

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
            if (qCol != null) Destroy(qCol);
        }

        private void CreateCityLabel(Transform parent, CityData city, float height, Font font)
        {
            var canvasObj = new GameObject("CityLabelCanvas");
            canvasObj.transform.SetParent(parent);
            canvasObj.transform.localPosition = new Vector3(0, height, 0);

            var canvas = canvasObj.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.WorldSpace;
            var rt = canvasObj.GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(300, 56);
            rt.localScale = Vector3.one * 0.028f;

            // Har doim kameraga qarab turishi uchun
            canvasObj.AddComponent<BillboardLookAtCamera>();

            // Chiroyli multfilm hoshiyali fon (Rounded pill)
            Sprite uiSprite = Resources.Load<Sprite>("UI/rounded_rect");
            var bgObj = new GameObject("Bg", typeof(RectTransform), typeof(Image));
            bgObj.transform.SetParent(canvasObj.transform, false);
            var bgRt = bgObj.GetComponent<RectTransform>();
            bgRt.anchorMin = Vector2.zero;
            bgRt.anchorMax = Vector2.one;
            bgRt.sizeDelta = Vector2.zero;
            var bgImg = bgObj.GetComponent<Image>();
            if (uiSprite != null)
            {
                bgImg.sprite = uiSprite;
                bgImg.type = Image.Type.Sliced;
            }
            bgImg.color = new Color(0.06f, 0.10f, 0.16f, 0.88f);

            // Chap tomondagi bayroq nishoni (Flag Icon)
            Sprite flagSprite = Resources.Load<Sprite>($"Flags/png/{city.CountryCode.ToUpperInvariant()}");
            if (flagSprite != null)
            {
                var flagImgObj = new GameObject("FlagIcon", typeof(RectTransform), typeof(Image));
                flagImgObj.transform.SetParent(canvasObj.transform, false);
                var fRt = flagImgObj.GetComponent<RectTransform>();
                fRt.anchorMin = new Vector2(0, 0.5f);
                fRt.anchorMax = new Vector2(0, 0.5f);
                fRt.pivot = new Vector2(0, 0.5f);
                fRt.anchoredPosition = new Vector2(12, 0);
                fRt.sizeDelta = new Vector2(42, 28);
                var fImg = flagImgObj.GetComponent<Image>();
                fImg.sprite = flagSprite;
            }

            // Matn: Shahar nomi va oltin yulduz
            var txtObj = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtObj.transform.SetParent(canvasObj.transform, false);
            var txtRt = txtObj.GetComponent<RectTransform>();
            txtRt.anchorMin = Vector2.zero;
            txtRt.anchorMax = Vector2.one;
            txtRt.offsetMin = new Vector2(60, 0);
            txtRt.offsetMax = new Vector2(-10, 0);
            var txt = txtObj.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 22;
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

        private void Start()
        {
            if (Camera.main != null)
            {
                _camTransform = Camera.main.transform;
            }
        }

        private void LateUpdate()
        {
            if (_camTransform == null && Camera.main != null)
            {
                _camTransform = Camera.main.transform;
            }

            if (_camTransform != null)
            {
                transform.rotation = _camTransform.rotation;
            }
        }
    }
}
