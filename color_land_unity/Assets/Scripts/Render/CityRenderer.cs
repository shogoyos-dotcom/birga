using System.Collections.Generic;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// Shaharlarning 3D vizual tasviri (CityRenderer).
    /// Arena ustida har bir shahar uchun 3D me'moriy belgilar va bayroq ustunlarini render qiladi.
    /// Shahar egallanganda uning rangini dinamik yangilaydi.
    /// </summary>
    public class CityRenderer : MonoBehaviour
    {
        private readonly List<GameObject> _cityObjects = new List<GameObject>();
        private CitySystem _citySystem;
        private Material _neutralMat;
        private Material _playerMat;

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
        }

        private void CreateMaterials()
        {
            Shader litShader = Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard");
            _neutralMat = new Material(litShader) { color = new Color(0.85f, 0.85f, 0.88f) };
            _playerMat = new Material(litShader) { color = new Color(0.15f, 0.65f, 1.0f) };
        }

        private void SpawnCityMeshes()
        {
            foreach (var go in _cityObjects)
            {
                if (go != null) Destroy(go);
            }
            _cityObjects.Clear();

            if (_citySystem == null) return;

            foreach (var city in _citySystem.Cities)
            {
                var cityRoot = new GameObject($"City_{city.Name}");
                cityRoot.transform.SetParent(transform);
                cityRoot.transform.position = city.WorldPos;

                // 1. Asos (Poydevor silindri)
                float scale = city.Category == CityCategory.Large ? 1.4f : (city.Category == CityCategory.Medium ? 1.1f : 0.8f);
                var baseObj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
                baseObj.name = "Base";
                baseObj.transform.SetParent(cityRoot.transform);
                baseObj.transform.localPosition = new Vector3(0, 0.15f * scale, 0);
                baseObj.transform.localScale = new Vector3(0.9f * scale, 0.15f * scale, 0.9f * scale);
                baseObj.GetComponent<Renderer>().sharedMaterial = _neutralMat;

                var col = baseObj.GetComponent<Collider>();
                if (col != null) col.isTrigger = true;

                // 2. Markaziy bino (Katta shahar uchun baland kub, kichik uchun ixcham)
                var building = GameObject.CreatePrimitive(PrimitiveType.Cube);
                building.name = "Building";
                building.transform.SetParent(cityRoot.transform);
                float bHeight = city.Category == CityCategory.Large ? 1.8f : (city.Category == CityCategory.Medium ? 1.2f : 0.8f);
                building.transform.localPosition = new Vector3(0, bHeight * 0.5f + 0.3f, 0);
                building.transform.localScale = new Vector3(0.6f * scale, bHeight, 0.6f * scale);
                building.GetComponent<Renderer>().sharedMaterial = _neutralMat;

                var bCol = building.GetComponent<Collider>();
                if (bCol != null) bCol.isTrigger = true;

                // 3. Bayroq / Uchi (Poytaxtlar uchun oltin konus/shar)
                if (city.IsCapital)
                {
                    var spire = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                    spire.name = "Spire";
                    spire.transform.SetParent(cityRoot.transform);
                    spire.transform.localPosition = new Vector3(0, bHeight + 0.55f, 0);
                    spire.transform.localScale = Vector3.one * (0.45f * scale);
                    var spireMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"))
                    {
                        color = new Color(1.0f, 0.82f, 0.15f) // Gold
                    };
                    spire.GetComponent<Renderer>().sharedMaterial = spireMat;
                    var sCol = spire.GetComponent<Collider>();
                    if (sCol != null) sCol.isTrigger = true;
                }

                _cityObjects.Add(cityRoot);
            }
        }

        private void OnCityCaptured(CityData city, byte capturerId, int reward)
        {
            int index = city.Id - 1;
            if (index >= 0 && index < _cityObjects.Count)
            {
                var root = _cityObjects[index];
                if (root == null) return;

                Color c = capturerId == 1 ? new Color(0.15f, 0.65f, 1.0f) : UnityEngine.Random.ColorHSV(0f, 1f, 0.6f, 0.9f, 0.7f, 1.0f);
                var capMat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard")) { color = c };

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
}
