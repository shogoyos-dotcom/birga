using System;
using System.Collections;
using UnityEngine;

namespace ColorLand.Logic
{
    /// <summary>
    /// O'yin maydoni panjarasi (GameGrid).
    /// Har bir katak egasini (0=egasiz, 1=o'yinchi, 2..21=botlar, 255=suv) saqlaydi.
    /// Quruqlik va suv niqoblarini boshqaradi.
    /// </summary>
    public class GameGrid
    {
        public const byte OWNER_NONE = 0;
        public const byte OWNER_PLAYER = 1;
        public const byte OWNER_WATER = 255;

        public int Width { get; private set; }
        public int Height { get; private set; }
        public float CellSize { get; private set; }

        private readonly byte[] _cells;
        private readonly BitArray _landMask;
        private readonly bool _hasLandMask;

        public GameGrid(int width, int height, float cellSize = 1.0f, byte[] landMaskBytes = null)
        {
            Width = width;
            Height = height;
            CellSize = cellSize;
            _cells = new byte[width * height];

            if (landMaskBytes != null && landMaskBytes.Length > 0)
            {
                _landMask = new BitArray(landMaskBytes);
                _hasLandMask = true;

                // Suv kataklarini OWNER_WATER (255) deb belgilaymiz
                for (int y = 0; y < height; y++)
                {
                    for (int x = 0; x < width; x++)
                    {
                        if (!IsLand(x, y))
                        {
                            _cells[Index(x, y)] = OWNER_WATER;
                        }
                    }
                }
            }
            else
            {
                _landMask = null;
                _hasLandMask = false;
            }
        }

        [System.Runtime.CompilerServices.MethodImpl(System.Runtime.CompilerServices.MethodImplOptions.AggressiveInlining)]
        public int Index(int x, int y) => y * Width + x;

        public bool InBounds(int x, int y)
        {
            return x >= 0 && x < Width && y >= 0 && y < Height;
        }

        public bool IsLand(int x, int y)
        {
            if (!InBounds(x, y)) return false;
            if (!_hasLandMask) return true;
            int idx = Index(x, y);
            return idx < _landMask.Length && _landMask[idx];
        }

        public byte GetOwner(int x, int y)
        {
            if (!InBounds(x, y)) return OWNER_WATER;
            return _cells[Index(x, y)];
        }

        public void SetOwner(int x, int y, byte owner)
        {
            if (!InBounds(x, y)) return;
            // Agar katak suv bo'lsa va yangi ega suv bo'lmasa, o'rnatilmaydi
            if (_hasLandMask && !IsLand(x, y) && owner != OWNER_WATER) return;
            _cells[Index(x, y)] = owner;
        }

        public byte[] GetRawCells() => _cells;

        public Vector2Int WorldToGrid(Vector3 worldPos)
        {
            int gx = Mathf.FloorToInt((worldPos.x + (Width * CellSize * 0.5f)) / CellSize);
            int gz = Mathf.FloorToInt((worldPos.z + (Height * CellSize * 0.5f)) / CellSize);
            return new Vector2Int(gx, gz);
        }

        public Vector3 GridToWorld(int x, int y, float yHeight = 0f)
        {
            float wx = (x + 0.5f) * CellSize - (Width * CellSize * 0.5f);
            float wz = (y + 0.5f) * CellSize - (Height * CellSize * 0.5f);
            return new Vector3(wx, yHeight, wz);
        }

        public int CountOwnedCells(byte owner)
        {
            int count = 0;
            for (int i = 0; i < _cells.Length; i++)
            {
                if (_cells[i] == owner) count++;
            }
            return count;
        }

        public int TotalLandCells()
        {
            if (!_hasLandMask) return Width * Height;
            int count = 0;
            for (int y = 0; y < Height; y++)
            {
                for (int x = 0; x < Width; x++)
                {
                    if (IsLand(x, y)) count++;
                }
            }
            return count;
        }
    }
}
