using System;
using UnityEngine;
using ColorLand.Logic;

namespace ColorLand.Render
{
    /// <summary>
    /// Arena yuzasiga hudud va iz egalik ma'lumotlarini dinamik tekstura orqali uzatuvchi qatlam.
    /// Palitra teksturasi (_PaletteTex) orqali o'yinchi va barcha 20 ta bot ranglarini GPU ga yuboradi.
    /// </summary>
    public class PaintLayer : MonoBehaviour
    {
        [Header("References")]
        public Renderer ArenaRenderer;
        public Material ArenaMaterial;

        private GameGrid _grid;
        private Texture2D _indexTex;
        private Texture2D _paletteTex;
        private byte[] _pixelBuffer;
        private Color32[] _paletteBuffer;
        private bool _isDirty = false;
        private bool _paletteDirty = false;

        private static readonly int IndexTexId = Shader.PropertyToID("_IndexTex");
        private static readonly int PaletteTexId = Shader.PropertyToID("_PaletteTex");
        private static readonly int GridSizeId = Shader.PropertyToID("_GridSize");
        private static readonly int BeachColorId = Shader.PropertyToID("_BeachColor");
        private static readonly int UnclaimedColorId = Shader.PropertyToID("_UnclaimedColor");
        private static readonly int WaterColorId = Shader.PropertyToID("_WaterColor");

        public static readonly Color BeachColor = new Color(0.99f, 0.88f, 0.32f, 1.0f);
        public static readonly Color UnclaimedLandColor = new Color(0.57f, 0.88f, 0.48f, 1.0f);
        public static readonly Color OceanWaterColor = new Color(0.04f, 0.48f, 0.82f, 1.0f);

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

            // 1. R8 formati - har piksel bitta bayt (0..255 egasi)
            if (_indexTex != null) Destroy(_indexTex);
            _indexTex = new Texture2D(w, h, TextureFormat.R8, false, true)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                name = "Arena_IndexTex"
            };

            _pixelBuffer = new byte[w * h];

            // 2. 256x1 Palitra teksturasi (RGBA32)
            if (_paletteTex != null) Destroy(_paletteTex);
            _paletteTex = new Texture2D(256, 1, TextureFormat.RGBA32, false, false)
            {
                filterMode = FilterMode.Point,
                wrapMode = TextureWrapMode.Clamp,
                name = "Arena_PaletteTex"
            };

            _paletteBuffer = new Color32[256];
            InitDefaultPalette();

            UpdateFull();

            if (ArenaMaterial != null)
            {
                ArenaMaterial.SetTexture(IndexTexId, _indexTex);
                ArenaMaterial.SetTexture(PaletteTexId, _paletteTex);
                ArenaMaterial.SetVector(GridSizeId, new Vector4(w, h, 1.0f / w, 1.0f / h));
                ArenaMaterial.SetColor(BeachColorId, BeachColor);
                ArenaMaterial.SetColor(UnclaimedColorId, UnclaimedLandColor);
                ArenaMaterial.SetColor(WaterColorId, OceanWaterColor);
            }
        }

        private void InitDefaultPalette()
        {
            // 0: Egasiz quruqlik
            _paletteBuffer[0] = UnclaimedLandColor;

            // 1: O'yinchi (Moviy / Cyan)
            _paletteBuffer[1] = new Color(0.15f, 0.65f, 1.0f, 1.0f);

            // 2..21: 20 ta bot uchun oldindan tayyorlangan yorqin multfilm ranglar palitrasi
            Color[] presetBotColors = new Color[]
            {
                new Color(0.96f, 0.26f, 0.21f), // 2: Qizil
                new Color(1.00f, 0.60f, 0.00f), // 3: Sabzirang
                new Color(1.00f, 0.85f, 0.00f), // 4: Sariq
                new Color(0.61f, 0.15f, 0.69f), // 5: Binafsha
                new Color(0.91f, 0.12f, 0.39f), // 6: Pushti
                new Color(0.00f, 0.75f, 0.65f), // 7: Zangori (Teal)
                new Color(0.20f, 0.80f, 0.20f), // 8: Yashil
                new Color(0.40f, 0.20f, 0.60f), // 9: To'q binafsha
                new Color(1.00f, 0.40f, 0.60f), // 10: Och pushti
                new Color(0.10f, 0.85f, 0.90f), // 11: Yorqin moviy
                new Color(0.85f, 0.65f, 0.13f), // 12: Oltin
                new Color(0.70f, 0.30f, 0.10f), // 13: Jigarrang-to'q sariq
                new Color(0.10f, 0.50f, 0.80f), // 14: Kobalt
                new Color(0.80f, 0.10f, 0.50f), // 15: Fuksia
                new Color(0.30f, 0.70f, 0.90f), // 16: Havo rang
                new Color(0.60f, 0.80f, 0.20f), // 17: Laym
                new Color(0.95f, 0.50f, 0.30f), // 18: Shaftolirang
                new Color(0.50f, 0.50f, 0.90f), // 19: Nilrang
                new Color(0.90f, 0.20f, 0.40f), // 20: Malina
                new Color(0.15f, 0.75f, 0.45f), // 21: Zumrad
            };

            for (int i = 0; i < presetBotColors.Length; i++)
            {
                _paletteBuffer[i + 2] = presetBotColors[i];
            }

            // 22..254: Qolgan indekslar uchun tasodifiy to'ldirish
            for (int i = 22; i < 255; i++)
            {
                _paletteBuffer[i] = Color.HSVToRGB((i * 17 % 100) / 100f, 0.75f, 0.9f);
            }

            // 255: Suv
            _paletteBuffer[255] = OceanWaterColor;

            _paletteTex.SetPixels32(_paletteBuffer);
            _paletteTex.Apply(false, false);
        }

        public void SetPaletteColor(byte ownerId, Color color)
        {
            if (_paletteBuffer == null || _paletteTex == null) return;
            _paletteBuffer[ownerId] = color;
            _paletteDirty = true;
        }

        public void SetCell(int x, int y, byte owner)
        {
            if (_grid == null || !_grid.InBounds(x, y)) return;
            int idx = _grid.Index(x, y);
            if (_pixelBuffer[idx] != owner)
            {
                _pixelBuffer[idx] = owner;
                _isDirty = true;
            }
        }

        public void UpdateFull()
        {
            if (_grid == null || _indexTex == null) return;
            byte[] raw = _grid.GetRawCells();
            Buffer.BlockCopy(raw, 0, _pixelBuffer, 0, raw.Length);
            _indexTex.SetPixelData(_pixelBuffer, 0);
            _indexTex.Apply(false, false);
            _isDirty = false;
        }

        private void LateUpdate()
        {
            if (_isDirty && _indexTex != null)
            {
                _indexTex.SetPixelData(_pixelBuffer, 0);
                _indexTex.Apply(false, false);
                _isDirty = false;
            }

            if (_paletteDirty && _paletteTex != null)
            {
                _paletteTex.SetPixels32(_paletteBuffer);
                _paletteTex.Apply(false, false);
                _paletteDirty = false;
            }
        }

        private void OnDestroy()
        {
            if (_indexTex != null) Destroy(_indexTex);
            if (_paletteTex != null) Destroy(_paletteTex);
        }
    }
}
