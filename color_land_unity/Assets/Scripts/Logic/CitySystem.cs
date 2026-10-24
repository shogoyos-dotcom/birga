using System;
using System.Collections.Generic;
using UnityEngine;
using ColorLand.App;

namespace ColorLand.Logic
{
    public enum CityCategory
    {
        Small = 0,
        Medium = 1,
        Large = 2
    }

    public class CityData
    {
        public int Id;
        public string Name;
        public string CountryCode;
        public Vector2Int GridPos;
        public Vector3 WorldPos;
        public int Population;
        public bool IsCapital;
        public CityCategory Category;
        public byte OwnerId = 0; // 0 = Neutral
        public int RewardCoins = 50;

        public string LocalizedName => CityNames.GetName(Name);

        public bool IsOwnedBy(byte owner) => OwnerId == owner;
    }

    /// <summary>
    /// Shaharlar va hududiy istilo tizimi (CitySystem).
    /// Xaritadagi barcha shaharlarni O(1) indeksatsiyada saqlaydi va
    /// o'ralgan (capture) qilinganda mukofot va bildirishnomani faollashtiradi.
    /// </summary>
    public class CitySystem
    {
        public readonly List<CityData> Cities = new List<CityData>();
        private readonly Dictionary<int, CityData> _byCellIndex = new Dictionary<int, CityData>();
        private readonly GameGrid _grid;

        // Shahar egallanganda hodisa (CityData, capturerId, rewardCoins)
        public event Action<CityData, byte, int> OnCityCaptured;

        public CitySystem(GameGrid grid)
        {
            _grid = grid;
        }

        /// <summary>
        /// Shaharlarni qo'shish va katak indeksi bo'yicha bog'lash.
        /// </summary>
        public void AddCity(string name, string countryCode, int gx, int gy, int pop, bool isCapital)
        {
            if (!_grid.InBounds(gx, gy) || !_grid.IsLand(gx, gy)) return;

            int cellIdx = _grid.Index(gx, gy);
            if (_byCellIndex.ContainsKey(cellIdx)) return; // bir katakda faqat bitta shahar

            CityCategory cat = CityCategory.Small;
            int reward = 50;
            if (isCapital || pop >= 1000000)
            {
                cat = CityCategory.Large;
                reward = 200;
            }
            else if (pop >= 200000)
            {
                cat = CityCategory.Medium;
                reward = 100;
            }

            var city = new CityData
            {
                Id = Cities.Count + 1,
                Name = name,
                CountryCode = countryCode.ToUpperInvariant(),
                GridPos = new Vector2Int(gx, gy),
                WorldPos = _grid.GridToWorld(gx, gy, 0.2f),
                Population = pop,
                IsCapital = isCapital,
                Category = cat,
                OwnerId = 0,
                RewardCoins = reward
            };

            Cities.Add(city);
            _byCellIndex[cellIdx] = city;
        }

        /// <summary>
        /// Standart shahar to'plamini yuklash (masalan poytaxtlar va megapolislar).
        /// </summary>
        public void LoadDefaultCities(int width, int height)
        {
            Cities.Clear();
            _byCellIndex.Clear();

            // Asosiy shaharlar ro'yxati (har xil toifadagi va mamlakatlardagi)
            var sampleCities = new[]
            {
                new { Name = "Tashkent", Code = "UZ", X = width / 2, Y = height / 2 + 10, Pop = 2500000, Cap = true },
                new { Name = "Samarkand", Code = "UZ", X = width / 2 - 12, Y = height / 2 + 6, Pop = 550000, Cap = false },
                new { Name = "Bukhara", Code = "UZ", X = width / 2 - 22, Y = height / 2 + 4, Pop = 280000, Cap = false },
                new { Name = "Paris", Code = "FR", X = width / 2 - 25, Y = height / 2 + 25, Pop = 2160000, Cap = true },
                new { Name = "London", Code = "GB", X = width / 2 - 28, Y = height / 2 + 35, Pop = 8980000, Cap = true },
                new { Name = "Berlin", Code = "DE", X = width / 2 - 10, Y = height / 2 + 28, Pop = 3645000, Cap = true },
                new { Name = "Rome", Code = "IT", X = width / 2 - 18, Y = height / 2 + 16, Pop = 2870000, Cap = true },
                new { Name = "Madrid", Code = "ES", X = width / 2 - 35, Y = height / 2 + 15, Pop = 3223000, Cap = true },
                new { Name = "Tokyo", Code = "JP", X = width / 2 + 35, Y = height / 2 + 20, Pop = 13960000, Cap = true },
                new { Name = "Seoul", Code = "KR", X = width / 2 + 28, Y = height / 2 + 22, Pop = 9776000, Cap = true },
                new { Name = "Beijing", Code = "CN", X = width / 2 + 20, Y = height / 2 + 25, Pop = 21540000, Cap = true },
                new { Name = "Dubai", Code = "AE", X = width / 2 + 10, Y = height / 2 - 15, Pop = 3331000, Cap = false },
                new { Name = "Cairo", Code = "EG", X = width / 2 - 5, Y = height / 2 - 20, Pop = 9540000, Cap = true },
                new { Name = "Port Sudan", Code = "SD", X = width / 2 + 2, Y = height / 2 - 30, Pop = 489000, Cap = false },
                new { Name = "Nairobi", Code = "KE", X = width / 2 + 5, Y = height / 2 - 40, Pop = 4397000, Cap = true },
                new { Name = "New York", Code = "US", X = width / 2 - 40, Y = height / 2 + 22, Pop = 8419000, Cap = false },
                new { Name = "Washington, D.C.", Code = "US", X = width / 2 - 42, Y = height / 2 + 18, Pop = 689545, Cap = true },
                new { Name = "Toronto", Code = "CA", X = width / 2 - 38, Y = height / 2 + 30, Pop = 2731571, Cap = false },
                new { Name = "Rio de Janeiro", Code = "BR", X = width / 2 - 25, Y = height / 2 - 35, Pop = 6748000, Cap = false },
                new { Name = "Sydney", Code = "AU", X = width / 2 + 40, Y = height / 2 - 35, Pop = 5312000, Cap = false },
            };

            foreach (var sc in sampleCities)
            {
                // Quruqlik katagini topish
                int cx = Mathf.Clamp(sc.X, 2, width - 3);
                int cy = Mathf.Clamp(sc.Y, 2, height - 3);

                if (_grid.IsLand(cx, cy))
                {
                    AddCity(sc.Name, sc.Code, cx, cy, sc.Pop, sc.Cap);
                }
                else
                {
                    // Eng yaqin quruqlik katagini qidirish
                    bool placed = false;
                    for (int r = 1; r < 10 && !placed; r++)
                    {
                        for (int dy = -r; dy <= r && !placed; dy++)
                        {
                            for (int dx = -r; dx <= r && !placed; dx++)
                            {
                                int nx = cx + dx;
                                int ny = cy + dy;
                                if (_grid.InBounds(nx, ny) && _grid.IsLand(nx, ny))
                                {
                                    AddCity(sc.Name, sc.Code, nx, ny, sc.Pop, sc.Cap);
                                    placed = true;
                                }
                            }
                        }
                    }
                }
            }
        }

        /// <summary>
        /// Egallangan kataklar orasida shahar bor-yo'qligini O(1) tezlikda tekshiradi.
        /// </summary>
        public void CheckCityCapture(byte capturerId, int cellX, int cellY)
        {
            if (!_grid.InBounds(cellX, cellY)) return;
            int cellIdx = _grid.Index(cellX, cellY);

            if (_byCellIndex.TryGetValue(cellIdx, out var city))
            {
                if (city.OwnerId != capturerId)
                {
                    city.OwnerId = capturerId;
                    OnCityCaptured?.Invoke(city, capturerId, city.RewardCoins);
                }
            }
        }

        public CityData GetCityAt(int x, int y)
        {
            if (!_grid.InBounds(x, y)) return null;
            _byCellIndex.TryGetValue(_grid.Index(x, y), out var city);
            return city;
        }
    }
}
