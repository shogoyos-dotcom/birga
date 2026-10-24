using System.Collections.Generic;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// O'yinchi va botlar orqasidan chiziluvchi 3D iz lentasi (Trail Ribbon).
    /// LineRenderer yordamida o'yinchining haqiqiy yo'lini silliq chizadi.
    /// </summary>
    [RequireComponent(typeof(LineRenderer))]
    public class TrailRibbon : MonoBehaviour
    {
        public PlayerState State;
        public float RibbonHeight = 0.15f;
        public float RibbonWidth = 0.6f;

        private LineRenderer _line;
        private GameGrid _grid;

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
            }
        }

        public void Initialize(GameGrid grid, Color trailColor)
        {
            EnsureLineRenderer();
            _grid = grid;
            _line.startColor = trailColor;
            _line.endColor = trailColor;

            // Agar material bo'lmasa, standart Unlit material yaratamiz
            if (_line.material == null || _line.material.name.StartsWith("Default"))
            {
                var shader = Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Sprites/Default");
                if (shader != null)
                {
                    _line.material = new Material(shader) { color = trailColor };
                }
            }
        }

        private void LateUpdate()
        {
            if (State == null || State.Entity == null || _grid == null)
            {
                _line.positionCount = 0;
                return;
            }

            var trail = State.Entity.Trail;
            if (trail == null || trail.Count == 0)
            {
                _line.positionCount = 0;
                return;
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
    }
}
