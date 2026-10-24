using System.Collections.Generic;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// O'yinchi va botlar orqasidan chiziluvchi 3D iz lentasi (Trail Ribbon).
    /// LineRenderer yordamida o'yinchining haqiqiy yo'lini silliq chizadi.
    /// Xavf to'lqini paytida qizil yonib-o'chish (flash) effektini beradi.
    /// </summary>
    [RequireComponent(typeof(LineRenderer))]
    public class TrailRibbon : MonoBehaviour
    {
        public PlayerState State;
        public float RibbonHeight = 0.15f;
        public float RibbonWidth = 0.65f;

        private LineRenderer _line;
        private GameGrid _grid;
        private Material _trailMat;
        private static readonly int DangerFlashId = Shader.PropertyToID("_DangerFlash");
        private static readonly int ColorId = Shader.PropertyToID("_Color");

        private void Awake()
        {
            EnsureLineRenderer();
        }

        private void EnsureLineRenderer()
        {
            if (_line == null)
            {
                _line = GetComponent<LineRenderer>() ?? gameObject.AddComponent<LineRenderer>();
                _line.startWidth = RibbonWidth;
                _line.endWidth = RibbonWidth;
                _line.useWorldSpace = true;
                _line.alignment = LineAlignment.TransformZ;
                _line.shadowCastingMode = UnityEngine.Rendering.ShadowCastingMode.Off;
                _line.receiveShadows = false;
            }
        }

        public void Initialize(GameGrid grid, Color trailColor)
        {
            EnsureLineRenderer();
            _grid = grid;
            _line.startColor = trailColor;
            _line.endColor = trailColor;

            Shader shader = Shader.Find("ColorLand/TrailShader")
                         ?? Shader.Find("Universal Render Pipeline/Unlit")
                         ?? Shader.Find("Sprites/Default")
                         ?? Shader.Find("Mobile/Particles/Alpha Blended");

            if (shader != null)
            {
                _trailMat = new Material(shader)
                {
                    color = trailColor,
                    name = "M_TrailInstance"
                };
                if (_trailMat.HasProperty(ColorId)) _trailMat.SetColor(ColorId, trailColor);
                _line.material = _trailMat;
            }
        }

        private void LateUpdate()
        {
            if (State == null || State.Entity == null || _grid == null || _line == null)
            {
                if (_line != null) _line.positionCount = 0;
                return;
            }

            var trail = State.Entity.Trail;
            if (trail == null || trail.Count == 0)
            {
                _line.positionCount = 0;
                return;
            }

            // Xavf effekti: agar izga dushman tekkan bo'lsa, xavf to'lqini davomida qizil pulsatsiya
            if (_trailMat != null && _trailMat.HasProperty(DangerFlashId))
            {
                float flash = State.Entity.Danger != null ? Mathf.PingPong(Time.time * 8.0f, 1.0f) : 0.0f;
                _trailMat.SetFloat(DangerFlashId, flash);
            }

            // Iz kataklari soni + joriy o'yinchi boshi pozitsiyasi
            int pointCount = trail.Count + 1;
            _line.positionCount = pointCount;

            for (int i = 0; i < trail.Count; i++)
            {
                Vector3 worldPos = _grid.GridToWorld(trail[i].x, trail[i].y, RibbonHeight);
                _line.SetPosition(i, worldPos);
            }

            // Oxirgi nuqta - o'yinchining ayni paytdagi bosh pozitsiyasi
            Vector3 headPos = State.Entity.Position;
            headPos.y = RibbonHeight;
            _line.SetPosition(pointCount - 1, headPos);
        }

        private void OnDestroy()
        {
            if (_trailMat != null) Destroy(_trailMat);
        }
    }
}
