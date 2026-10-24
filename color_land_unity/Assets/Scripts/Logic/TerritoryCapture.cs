using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.Logic
{
    /// <summary>
    /// Hudud egallash tizimi (TerritoryCapture).
    /// O'yinchi izini yozadi, halqa yopilganda yopiq quruqlik sohasini (flood fill) aniqlab,
    /// barcha o'ralgan kataklarni egallaydi.
    /// Suv kataklari hech qachon egallanmaydi.
    /// </summary>
    public class TerritoryCapture
    {
        private readonly GameGrid _grid;
        public CitySystem CitySystem { get; set; }

        public TerritoryCapture(GameGrid grid, CitySystem citySystem = null)
        {
            _grid = grid;
            CitySystem = citySystem;
        }

        /// <summary>
        /// Halqa yopilganda ichki sohani aniqlab, egallash jarayonini amalga oshiradi.
        /// </summary>
        /// <param name="owner">Egallovchi (1=o'yinchi, 2..21=bot)</param>
        /// <param name="trail">O'yinchi qoldirgan iz kataklari</param>
        /// <returns>Yangi egallangan kataklar soni</returns>
        public int ExecuteCapture(byte owner, List<Vector2Int> trail)
        {
            if (trail == null || trail.Count == 0) return 0;

            int width = _grid.Width;
            int height = _grid.Height;

            // 1. Chegara (Boundary) niqobi:
            // Mavjud o'z hududi + yangi iz chegarani tashkil etadi.
            bool[] isBoundary = new bool[width * height];
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    if (_grid.GetOwner(x, y) == owner)
                    {
                        isBoundary[_grid.Index(x, y)] = true;
                    }
                }
            }

            foreach (var pt in trail)
            {
                if (_grid.InBounds(pt.x, pt.y))
                {
                    isBoundary[_grid.Index(pt.x, pt.y)] = true;
                }
            }

            // 2. Tashqi sohani aniqlash (Outside flood fill):
            // Panjara chetlaridagi kataklardan boshlab BFS yuritamiz.
            bool[] reachedFromOutside = new bool[width * height];
            Queue<Vector2Int> queue = new Queue<Vector2Int>(width * 2 + height * 2);

            void EnqueueIfOutside(int x, int y)
            {
                if (!_grid.InBounds(x, y)) return;
                int idx = _grid.Index(x, y);
                if (!isBoundary[idx] && !reachedFromOutside[idx])
                {
                    reachedFromOutside[idx] = true;
                    queue.Enqueue(new Vector2Int(x, y));
                }
            }

            // Chekka qatorlar va ustunlar
            for (int x = 0; x < width; x++)
            {
                EnqueueIfOutside(x, 0);
                EnqueueIfOutside(x, height - 1);
            }
            for (int y = 0; y < height; y++)
            {
                EnqueueIfOutside(0, y);
                EnqueueIfOutside(width - 1, y);
            }

            int[] dx = { 1, -1, 0, 0 };
            int[] dy = { 0, 0, 1, -1 };

            while (queue.Count > 0)
            {
                Vector2Int curr = queue.Dequeue();

                for (int d = 0; d < 4; d++)
                {
                    int nx = curr.x + dx[d];
                    int ny = curr.y + dy[d];

                    if (_grid.InBounds(nx, ny))
                    {
                        int nidx = _grid.Index(nx, ny);
                        if (!isBoundary[nidx] && !reachedFromOutside[nidx])
                        {
                            reachedFromOutside[nidx] = true;
                            queue.Enqueue(new Vector2Int(nx, ny));
                        }
                    }
                }
            }

            // 3. Egallash:
            // Tashqi sohadan yetib borilmagan va quruqlik bo'lgan barcha kataklar o'ralgan (enclosed) hisoblanadi!
            int newlyCaptured = 0;
            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    int idx = _grid.Index(x, y);

                    // Faqat quruqlik bo'lsa va tashqaridan yetib borilmagan bo'lsa
                    if (_grid.IsLand(x, y) && !reachedFromOutside[idx])
                    {
                        if (_grid.GetOwner(x, y) != owner)
                        {
                            _grid.SetOwner(x, y, owner);
                            newlyCaptured++;
                            CitySystem?.CheckCityCapture(owner, x, y);
                        }
                    }
                }
            }

            return newlyCaptured;
        }

        /// <summary>
        /// O'yinchining boshlang'ich (spawn) hududini yaratish (masalan 5x5 doira).
        /// </summary>
        public void SpawnInitialTerritory(byte owner, Vector2Int center, int radius = 2)
        {
            for (int dy = -radius; dy <= radius; dy++)
            {
                for (int dx = -radius; dx <= radius; dx++)
                {
                    if (dx * dx + dy * dy <= radius * radius + 1)
                    {
                        int x = center.x + dx;
                        int y = center.y + dy;
                        if (_grid.InBounds(x, y) && _grid.IsLand(x, y))
                        {
                            _grid.SetOwner(x, y, owner);
                        }
                    }
                }
            }
        }
    }
}
