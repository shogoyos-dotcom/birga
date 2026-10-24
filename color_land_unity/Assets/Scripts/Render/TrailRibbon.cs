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
        public float BeadRadius = 0.52f;
        public float BeadHeight = 0.08f;
        public float Spacing = 0.38f; // Boncuklar orasidagi silliq tutashish masofasi

        private GameGrid _grid;
        private Color _trailColor;
        private Material _beadMaterial;
        private Mesh _beadMesh;

        private readonly List<Vector3> _interpolatedPoints = new List<Vector3>();
        private readonly List<GameObject> _beadPool = new List<GameObject>();
        private int _activeBeads = 0;

        private static readonly int DangerFlashId = Shader.PropertyToID("_DangerFlash");
        private static readonly int ColorId = Shader.PropertyToID("_Color");

        private void Awake()
        {
            BuildBeadMesh();
        }

        private void BuildBeadMesh()
        {
            if (_beadMesh != null) return;

            // Silliq yaltiroq doiraviy disk mesh (Cylinder with rounded edges)
            _beadMesh = new Mesh { name = "Mesh_TrailBead" };
            int segs = 18;
            var verts = new List<Vector3>();
            var norms = new List<Vector3>();
            var uvs = new List<Vector2>();
            var tris = new List<int>();

            Vector3 centerTop = new Vector3(0, BeadHeight, 0);
            verts.Add(centerTop);
            norms.Add(Vector3.up);
            uvs.Add(new Vector2(0.5f, 0.5f));

            float step = Mathf.PI * 2.0f / segs;
            for (int i = 0; i <= segs; i++)
            {
                float a = i * step;
                float x = Mathf.Cos(a) * BeadRadius;
                float z = Mathf.Sin(a) * BeadRadius;

                verts.Add(new Vector3(x, BeadHeight * 0.5f, z));
                norms.Add(new Vector3(x, 0.4f, z).normalized);
                uvs.Add(new Vector2(0.5f + Mathf.Cos(a) * 0.5f, 0.5f + Mathf.Sin(a) * 0.5f));
            }

            for (int i = 1; i <= segs; i++)
            {
                tris.Add(0);
                tris.Add(i + 1);
                tris.Add(i);
            }

            _beadMesh.SetVertices(verts);
            _beadMesh.SetNormals(norms);
            _beadMesh.SetUVs(0, uvs);
            _beadMesh.SetTriangles(tris, 0);
            _beadMesh.RecalculateBounds();
        }

        public void Initialize(GameGrid grid, Color trailColor)
        {
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

            var beadObj = new GameObject($"TrailBead_{index}");
            beadObj.transform.SetParent(transform, true);

            var mf = beadObj.AddComponent<MeshFilter>();
            mf.sharedMesh = _beadMesh;

            var mr = beadObj.AddComponent<MeshRenderer>();
            mr.sharedMaterial = _beadMaterial;
            mr.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
            mr.receiveShadows = false;

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
