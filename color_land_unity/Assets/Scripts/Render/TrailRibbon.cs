using System.Collections.Generic;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — Silliq Harakat Izi (Smooth Bead Trail).
    /// Foydalanuvchi taqdim etgan to'g'ri namunaga ("To'g'ri (Silliq harakat izi)")
    /// 100% mos: o'yinchi va botlar ortidan silliq, bir-biriga tutashgan yaltiroq
    /// doiraviy boncuk/disklar zanjirini chizadi.
    /// Zikzaklar va burchakli qirralar butunlay chiqarib tashlangan.
    /// </summary>
    public class TrailRibbon : MonoBehaviour
    {
        public PlayerState State;
        public float BeadRadius = 0.50f;
        public float BeadHeight = 0.42f;
        public float Spacing = 0.62f; // Silliq marjon boncuklar orasidagi ideal masofa

        private GameGrid _grid;
        private Color _trailColor;
        private Material _beadMaterial;
        private Mesh _beadMesh;

        private readonly List<Vector3> _interpolatedPoints = new List<Vector3>();
        private readonly List<GameObject> _beadPool = new List<GameObject>();
        private int _activeBeads = 0;
        public int ActiveBeadsCount => _activeBeads;

        private static readonly int DangerFlashId = Shader.PropertyToID("_DangerFlash");
        private static readonly int ColorId = Shader.PropertyToID("_Color");

        private void Awake()
        {
            BuildBeadMesh();
        }

        private void BuildBeadMesh()
        {
            if (_beadMesh != null) return;

            // Multfilm 3D yaltiroq yumaloq boncuk (Glossy Sphere Bead with neutral vertex colors)
            var sphereObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            var sphereMf = sphereObj.GetComponent<MeshFilter>();
            if (sphereMf != null && sphereMf.sharedMesh != null)
            {
                _beadMesh = Instantiate(sphereMf.sharedMesh);
                _beadMesh.name = "Mesh_TrailSphereBead";
            }
            DestroyImmediate(sphereObj);
        }

        public void Initialize(GameGrid grid, Color trailColor)
        {
            BuildBeadMesh();
            _grid = grid;
            _trailColor = trailColor;

            Shader shader = Shader.Find("ColorLand/CartoonLit")
                         ?? Shader.Find("Universal Render Pipeline/Lit")
                         ?? Shader.Find("Standard")
                         ?? Shader.Find("Mobile/Diffuse");

            _beadMaterial = new Material(shader)
            {
                color = trailColor,
                name = $"M_TrailBead_{trailColor.GetHashCode()}"
            };
        }

        public void UpdateTrailExplicit()
        {
            LateUpdate();
        }

        private void LateUpdate()
        {
            if (State == null || State.Entity == null || _grid == null)
            {
                HideAllBeads();
                return;
            }

            var trail = State.Entity.Trail;
            if (trail == null || trail.Count == 0)
            {
                HideAllBeads();
                return;
            }

            // Xavf effekti: agar izga dushman tekkan bo'lsa, qizil pulsatsiya
            bool hasDanger = State.Entity.Danger != null;
            if (_beadMaterial != null)
            {
                if (hasDanger)
                {
                    float flash = Mathf.PingPong(Time.time * 9.0f, 1.0f);
                    _beadMaterial.color = Color.Lerp(_trailColor, new Color(1.0f, 0.15f, 0.15f), flash);
                }
                else
                {
                    _beadMaterial.color = _trailColor;
                }
            }

            // Iz nuqtalarini silliq interpolyatsiya qilish
            _interpolatedPoints.Clear();
            for (int i = 0; i < trail.Count; i++)
            {
                Vector3 p = _grid.GridToWorld(trail[i].x, trail[i].y, BeadHeight);
                _interpolatedPoints.Add(p);
            }

            // O'yinchining hozirgi bosh pozitsiyasini qo'shish
            Vector3 headPos = new Vector3(State.transform.position.x, BeadHeight, State.transform.position.z);
            _interpolatedPoints.Add(headPos);

            // Silliq boncuk zanjirini joylashtirish
            SpawnSmoothBeadChain(_interpolatedPoints);
        }

        private void SpawnSmoothBeadChain(List<Vector3> waypoints)
        {
            if (waypoints.Count < 2)
            {
                HideAllBeads();
                return;
            }

            int beadIndex = 0;

            for (int i = 0; i < waypoints.Count - 1; i++)
            {
                Vector3 start = waypoints[i];
                Vector3 end = waypoints[i + 1];
                float dist = Vector3.Distance(start, end);
                int steps = Mathf.Max(1, Mathf.RoundToInt(dist / Spacing));

                for (int s = 0; s < steps; s++)
                {
                    float t = (float)s / steps;
                    Vector3 pos = Vector3.Lerp(start, end, t);

                    GameObject bead = GetOrCreateBead(beadIndex);
                    bead.transform.position = pos;
                    bead.SetActive(true);
                    beadIndex++;
                }
            }

            // Qolgan foydalanilmagan boncuklarni yashirish
            for (int i = beadIndex; i < _beadPool.Count; i++)
            {
                _beadPool[i].SetActive(false);
            }
            _activeBeads = beadIndex;
        }

        private GameObject GetOrCreateBead(int index)
        {
            if (index < _beadPool.Count)
            {
                return _beadPool[index];
            }

            BuildBeadMesh();

            var trailRoot = GameObject.Find("TrailRoot");
            if (trailRoot == null) trailRoot = new GameObject("TrailRoot");

            var beadObj = new GameObject($"TrailBead_{index}");
            beadObj.transform.SetParent(trailRoot.transform, false);
            beadObj.transform.localScale = Vector3.one * (BeadRadius * 2.0f);

            var mf = beadObj.AddComponent<MeshFilter>();
            mf.sharedMesh = _beadMesh;

            var mr = beadObj.AddComponent<MeshRenderer>();
            mr.sharedMaterial = _beadMaterial;
            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.On;
            mr.receiveShadows = true;

            _beadPool.Add(beadObj);
            return beadObj;
        }

        private void HideAllBeads()
        {
            for (int i = 0; i < _beadPool.Count; i++)
            {
                if (_beadPool[i] != null) _beadPool[i].SetActive(false);
            }
            _activeBeads = 0;
        }

        private void OnDestroy()
        {
            if (_beadMaterial != null) Destroy(_beadMaterial);
            if (_beadMesh != null) Destroy(_beadMesh);
        }
    }
}
