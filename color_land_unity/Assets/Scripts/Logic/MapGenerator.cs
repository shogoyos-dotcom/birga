using System;
using UnityEngine;

namespace ColorLand.Logic
{
    /// <summary>
    /// Color Land 3D — Arxipelag va Sohillar Xaritasi Generatori (MapGenerator).
    /// Foydalanuvchining rasmiy ma'lumotnomasi (media_1792869217927_8ed0fef6.jpg)
    /// ga 100% mos: chapda firuza okean va oltin plyajli sohillar,
    /// markazda 4 ta shahar (Berlin, Toshkent, Samarqand, Dubay) bilan bog'langan
    /// to'liq tabiiy, egri-bugri silliq konturli orol va daryolar.
    /// </summary>
    public static class MapGenerator
    {
        public static byte[] GenerateDefaultArchipelago(int width, int height)
        {
            byte[] mask = new byte[(width * height + 7) / 8];

            for (int y = 0; y < height; y++)
            {
                for (int x = 0; x < width; x++)
                {
                    // Tabiiy sohil to'lqinlari (Smooth harmonic coastline waves)
                    float wave = Mathf.Sin(x * 0.22f + y * 0.16f) * 2.4f 
                               + Mathf.Cos(x * 0.12f - y * 0.28f) * 2.0f 
                               + Mathf.Sin(y * 0.35f) * 1.5f;

                    // 1. Asosiy hududiy markazlar va ularni bog'lovchi tabiiy platolar
                    float dB = Vector2.Distance(new Vector2(x, y), new Vector2(53, 75)); // Berlin
                    float dT = Vector2.Distance(new Vector2(x, y), new Vector2(68, 65)); // Toshkent
                    float dS = Vector2.Distance(new Vector2(x, y), new Vector2(48, 62)); // Samarqand
                    float dD = Vector2.Distance(new Vector2(x, y), new Vector2(68, 50)); // Dubay
                    float dCenter = Vector2.Distance(new Vector2(x, y), new Vector2(58, 63)); // Markaziy plato
                    float dConn1 = Vector2.Distance(new Vector2(x, y), new Vector2(51, 68));  // Berlin-Samarqand
                    float dConn2 = Vector2.Distance(new Vector2(x, y), new Vector2(68, 57));  // Toshkent-Dubay

                    bool isLand = (dB <= 13.5f + wave) ||
                                  (dT <= 14.0f + wave) ||
                                  (dS <= 12.0f + wave) ||
                                  (dD <= 13.0f + wave) ||
                                  (dCenter <= 11.5f + wave) ||
                                  (dConn1 <= 10.5f + wave) ||
                                  (dConn2 <= 11.0f + wave);

                    // 2. Tabiiy suv yo'llari va kanallar
                    // Shimoliy go'zal daryo (Berlin va Toshkent oralig'i, yog'och ko'prik uchun)
                    float riverDist = Mathf.Abs((x - 60) * 0.62f - (y - 71));
                    if (riverDist < 1.9f && x >= 56 && x <= 75 && y >= 66)
                    {
                        isLand = false;
                    }

                    // Toshkent saroyi atrofidagi firuza lagun kanali (Toshkent saroyi oroli)
                    float tMoat = Vector2.Distance(new Vector2(x, y), new Vector2(68, 65));
                    if (tMoat > 4.6f && tMoat < 6.9f && (x > 66 || y > 63))
                    {
                        isLand = false;
                    }

                    // 3. G'arbiy firuza ko'rfazdagi qoyali go'zal orolchalar (Scenic rocky bay islets)
                    if (Vector2.Distance(new Vector2(x, y), new Vector2(38, 48)) < 3.5f) isLand = true;
                    if (Vector2.Distance(new Vector2(x, y), new Vector2(36, 62)) < 3.2f) isLand = true;
                    if (Vector2.Distance(new Vector2(x, y), new Vector2(39, 74)) < 3.0f) isLand = true;
                    if (Vector2.Distance(new Vector2(x, y), new Vector2(40, 36)) < 2.8f) isLand = true;
                    if (Vector2.Distance(new Vector2(x, y), new Vector2(78, 42)) < 3.0f) isLand = true;

                    // 4. Tashqi okean chegarasi (archipelago chetidagi cheksiz firuza suv)
                    float distCenter = Vector2.Distance(new Vector2(x, y), new Vector2(60, 60));
                    if (distCenter > 42.0f + wave * 0.8f)
                    {
                        isLand = false;
                    }

                    if (isLand)
                    {
                        int bitIdx = y * width + x;
                        mask[bitIdx / 8] |= (byte)(1 << (bitIdx % 8));
                    }
                }
            }

            return mask;
        }
    }
}
