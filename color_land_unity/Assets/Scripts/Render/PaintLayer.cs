using System;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// Arena yuzasiga hudud va iz egalik ma'lumotlarini dinamik tekstura orqali uzatuvchi qatlam.
    /// </summary>
    public class PaintLayer : MonoBehaviour
    {
        [Header("References")]
        public Renderer ArenaRenderer;
        public Material ArenaMaterial;

        private GameGrid _grid;
        private Texture2D _indexTex;
        private byte[] _pixelBuffer;
        private bool _isDirty = false;

        private static readonly int IndexTexId = Shader.PropertyToID("_IndexTex");
        private static readonly int GridSizeId = Shader.PropertyToID("_GridSize");

        public void Initialize(GameGrid grid, Material material = null)
        {
            _grid = grid;
            if (material != null) ArenaMaterial = material;
            if (ArenaMaterial == null && ArenaRenderer != null)
            {
                ArenaMaterial = ArenaRenderer.material;
            }

            int w = _grid.Width;
            int h = _grid.Height;

            // R8 formati - har piksel bitta bayt (0..255)
            _indexTex = new Texture2D(w, h, TextureFormat.R8, false, true)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp
            };

            _pixelBuffer = new byte[w * h];
            UpdateFull();

            if (ArenaMaterial != null)
            {
                ArenaMaterial.SetTexture(IndexTexId, _indexTex);
                ArenaMaterial.SetVector(GridSizeId, new Vector4(w, h, 0, 0));
            }
        }

        public void SetCell(int x, int y, byte owner)
        {
            if (!_grid.InBounds(x, y)) return;
            int idx = _grid.Index(x, y);
            if (_pixelBuffer[idx] != owner)
            {
                _pixelBuffer[idx] = owner;
                _isDirty = true;
            }
        }

        public void UpdateFull()
        {
            byte[] raw = _grid.GetRawCells();
            Buffer.BlockCopy(raw, 0, _pixelBuffer, 0, raw.Length);
            _indexTex.SetPixelData(_pixelBuffer, 0);
            _indexTex.Apply(false, false);
            _isDirty = false;
        }

        private void LateUpdate()
        {
            if (_isDirty)
            {
                _indexTex.SetPixelData(_pixelBuffer, 0);
                _indexTex.Apply(false, false);
                _isDirty = false;
            }
        }

        private void OnDestroy()
        {
            if (_indexTex != null)
            {
                Destroy(_indexTex);
            }
        }
    }
}
