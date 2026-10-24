using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.Logic;
using ColorLand.App;

namespace ColorLand.Render
{
    /// <summary>
    /// Shaharlarning 3D vizual tasviri (CityRenderer).
    /// Arena ustida har bir shahar uchun 3D me'moriy belgilar, poytaxt shpili va
    /// bosh ustidagi ko'rinarli nom/bayroq bannerini render qiladi.
    /// Shahar egallanganda uning rangini dinamik yangilaydi.
    /// </summary>
    public class CityRenderer : MonoBehaviour
    {
        private readonly List<GameObject> _cityObjects = new List<GameObject>();
        private CitySystem _citySystem;
        private Material _neutralMat;
        private Material _playerMat;
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
            if (_neutralMat != null) Destroy(_neutralMat);
            if (_playerMat != null) Destroy(_playerMat);
        }

        private void CreateMaterials()
        {
            _litShader = Shader.Find("ColorLand/CartoonLit")
                      ?? Shader.Find("Universal Render Pipeline/Lit")
                      ?? Shader.Find("Standard")
                      ?? Shader.Find("Mobile/Diffuse");

            _neutralMat = new Material(_litShader)
            {
                color = new Color(0.88f, 0.90f, 0.94f),
                name = "M_CityNeutral"
            };

            _playerMat = new Material(_litShader)
            {
                color = new Color(0.15f, 0.65f, 1.0f),
                name = "M_CityPlayer"
            };
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

                float scale = city.Category == CityCategory.Large ? 1.4f : (city.Category == CityCategory.Medium ? 1.1f : 0.85f);

                // 1. Asos (Poydevor silindri)
                var baseObj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                baseObj.name = "Base";
                baseObj.transform.SetParent(cityRoot.transform);
                baseObj.transform.localPosition = new Vector3(0, 0.12f * scale, 0);
                baseObj.transform.localScale = new Vector3(1.1f * scale, 0.12f * scale, 1.1f * scale);
                baseObj.GetComponent<Renderer>().sharedMaterial = _neutralMat;

                var col = baseObj.GetComponent<Collider>();
                if (col != null) col.isTrigger = true;

                // 2. Markaziy bino
                var building = GameObject.CreatePrimitive(PrimitiveType.Cube);
                building.name = "Building";
                building.transform.SetParent(cityRoot.transform);
                float bHeight = city.Category == CityCategory.Large ? 2.0f : (city.Category == CityCategory.Medium ? 1.4f : 0.9f);
                building.transform.localPosition = new Vector3(0, bHeight * 0.5f + 0.25f, 0);
                building.transform.localScale = new Vector3(0.7f * scale, bHeight, 0.7f * scale);
                building.GetComponent<Renderer>().sharedMaterial = _neutralMat;

                var bCol = building.GetComponent<Collider>();
                if (bCol != null) bCol.isTrigger = true;

                // 3. Yon minoralar (Katta shaharlar uchun)
                if (city.Category == CityCategory.Large)
                {
                    for (int ti = -1; ti <= 1; ti += 2)
                    {
                        var tower = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                        tower.name = "Tower";
                        tower.transform.SetParent(cityRoot.transform);
                        tower.transform.localPosition = new Vector3(ti * 0.65f * scale, bHeight * 0.35f, 0);
                        tower.transform.localScale = new Vector3(0.35f * scale, bHeight * 0.35f, 0.35f * scale);
                        tower.GetComponent<Renderer>().sharedMaterial = _neutralMat;
                        var tCol = tower.GetComponent<Collider>();
                        if (tCol != null) tCol.isTrigger = true;
                    }
                }

                // 4. Poytaxt uchun oltin shpil
                if (city.IsCapital)
                {
                    var spire = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                    spire.name = "Spire";
                    spire.transform.SetParent(cityRoot.transform);
                    spire.transform.localPosition = new Vector3(0, bHeight + 0.5f, 0);
                    spire.transform.localScale = Vector3.one * (0.5f * scale);

                    var spireMat = new Material(_litShader)
                    {
                        color = new Color(1.0f, 0.82f, 0.15f), // Gold
                        name = "M_GoldSpire"
                    };
                    spire.GetComponent<Renderer>().sharedMaterial = spireMat;
                    var sCol = spire.GetComponent<Collider>();
                    if (sCol != null) sCol.isTrigger = true;
                }

                // 5. Shahar nomini ko'rsatuvchi 3D Billboard Canvas
                CreateCityLabel(cityRoot.transform, city, bHeight + 1.2f, font);

                _cityObjects.Add(cityRoot);
            }
        }

        private void CreateCityLabel(Transform parent, CityData city, float height, Font font)
        {
            var canvasObj = new GameObject("CityLabelCanvas");
            canvasObj.transform.SetParent(parent);
            canvasObj.transform.localPosition = new Vector3(0, height, 0);

            var canvas = canvasObj.AddComponent<Canvas>();
            canvas.renderMode = RenderMode.WorldSpace;
            var rt = canvasObj.GetComponent<RectTransform>();
            rt.sizeDelta = new Vector2(240, 50);
            rt.localScale = Vector3.one * 0.035f;

            // Kamera tomonga qaratish
            canvasObj.AddComponent<BillboardLookAtCamera>();

            // Orqa fon paneli
            var bgObj = new GameObject("Bg", typeof(RectTransform), typeof(Image));
            bgObj.transform.SetParent(canvasObj.transform, false);
            var bgRt = bgObj.GetComponent<RectTransform>();
            bgRt.anchorMin = Vector2.zero;
            bgRt.anchorMax = Vector2.one;
            bgRt.sizeDelta = Vector2.zero;
            var bgImg = bgObj.GetComponent<Image>();
            bgImg.color = new Color(0.08f, 0.12f, 0.18f, 0.85f);

            // Matn
            var txtObj = new GameObject("Text", typeof(RectTransform), typeof(Text));
            txtObj.transform.SetParent(canvasObj.transform, false);
            var txtRt = txtObj.GetComponent<RectTransform>();
            txtRt.anchorMin = Vector2.zero;
            txtRt.anchorMax = Vector2.one;
            txtRt.sizeDelta = Vector2.zero;
            var txt = txtObj.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = 20;
            txt.alignment = TextAnchor.MiddleCenter;
            txt.color = city.IsCapital ? new Color(1.0f, 0.88f, 0.35f) : Color.white;
            txt.fontStyle = city.IsCapital ? FontStyle.Bold : FontStyle.Normal;

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
                var capMat = new Material(_litShader)
                {
                    color = c,
                    name = $"M_CityCaptured_{capturerId}"
                };

                foreach (var r in root.GetComponentsInChildren<Renderer>())
                {
                    if (r.gameObject.name != "Spire")
                    {
                        r.sharedMaterial = capMat;
                    }
                }
            }
        }
    }

    /// <summary>
    /// Matn yoki ikonkani har doim kameraga to'g'rilab turuvchi oddiy komponent.
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
