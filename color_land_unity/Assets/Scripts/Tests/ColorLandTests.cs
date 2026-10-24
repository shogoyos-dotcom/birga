using System;
using System.Collections.Generic;
using UnityEngine;
using ColorLand.Logic;
using ColorLand.App;

namespace ColorLand.Tests
{
    public class TestRunner
    {
        private static int _passed = 0;
        private static int _failed = 0;

        public static void Main(string[] args)
        {
            Console.WriteLine("========================================");
            Console.WriteLine("COLOR LAND 3D — UNITY PHASE 8.4 TEST SUITE");
            Console.WriteLine("========================================");

            Test_GameGrid_CreationAndCoords();
            Test_GameGrid_LandMask();
            Test_TerritoryCapture_SpawnInitial();
            Test_TerritoryCapture_EnclosedArea();
            Test_TerritoryCapture_WaterExcluded();
            Test_Player_TrailAndSuicide();
            Test_Player_CoastlineSliding();
            Test_Strings_Localization();
            Test_Strings_RussianCompleteness();
            Test_LanguageInfo_All15Languages();
            Test_CityNames_RussianTranslation();
            Test_CitySystem_CaptureAndReward();
            Test_TrailDanger_ChasingAndSurvival();
            Test_TrailDanger_CatchAndDeath();
            Test_VersionConfig_FormatAndValidation();
            Test_VersionConfig_BumpRules();
            Test_VersionConfig_AboutDisplay();
            Test_SaveManager_DefaultsAndLifecycle();
            Test_SaveManager_ExportImport();

            Console.WriteLine("========================================");
            Console.WriteLine($"NATIJA: {_passed} TA TEST O'TDI, {_failed} TA XATO");
            Console.WriteLine("========================================");

            if (_failed > 0)
            {
                Environment.Exit(1);
            }
        }

        private static void Assert(bool condition, string testName)
        {
            if (condition)
            {
                Console.WriteLine($"[PASS] {testName}");
                _passed++;
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"[FAIL] {testName}");
                Console.ResetColor();
                _failed++;
            }
        }

        private static void Test_GameGrid_CreationAndCoords()
        {
            var grid = new GameGrid(100, 100, 1.0f);
            Assert(grid.Width == 100 && grid.Height == 100, "GameGrid: O'lchamlar to'g'ri (100x100)");

            Vector3 worldPos = grid.GridToWorld(50, 50);
            Vector2Int backGrid = grid.WorldToGrid(worldPos);
            Assert(backGrid.x == 50 && backGrid.y == 50, "GameGrid: WorldToGrid va GridToWorld aniq teskari");

            grid.SetOwner(10, 10, 1);
            Assert(grid.GetOwner(10, 10) == 1, "GameGrid: Katak egasi to'g'ri o'rnatildi (Owner=1)");
        }

        private static void Test_GameGrid_LandMask()
        {
            byte[] mask = new byte[13];
            for (int y = 2; y <= 7; y++)
            {
                for (int x = 2; x <= 7; x++)
                {
                    int bitIdx = y * 10 + x;
                    mask[bitIdx / 8] |= (byte)(1 << (bitIdx % 8));
                }
            }

            var grid = new GameGrid(10, 10, 1.0f, mask);
            Assert(grid.IsLand(5, 5) == true, "GameGrid (Mask): Markaziy katak (5,5) quruqlik");
            Assert(grid.IsLand(0, 0) == false, "GameGrid (Mask): Chekka katak (0,0) suv");
            Assert(grid.GetOwner(0, 0) == GameGrid.OWNER_WATER, "GameGrid (Mask): Suv katak boshlang'ichda OWNER_WATER");

            grid.SetOwner(0, 0, 1);
            Assert(grid.GetOwner(0, 0) == GameGrid.OWNER_WATER, "GameGrid (Mask): Suv katagiga egalik o'rnatilmaydi");
        }

        private static void Test_TerritoryCapture_SpawnInitial()
        {
            var grid = new GameGrid(40, 40, 1.0f);
            var capture = new TerritoryCapture(grid);

            capture.SpawnInitialTerritory(1, new Vector2Int(20, 20), 2);
            int owned = grid.CountOwnedCells(1);
            Assert(owned >= 13 && owned <= 25, $"TerritoryCapture: Boshlang'ich spawn hududi yaratildi ({owned} katak)");
            Assert(grid.GetOwner(20, 20) == 1, "TerritoryCapture: Spawn markazi o'yinchi mulki");
        }

        private static void Test_TerritoryCapture_EnclosedArea()
        {
            var grid = new GameGrid(30, 30, 1.0f);
            var capture = new TerritoryCapture(grid);

            capture.SpawnInitialTerritory(1, new Vector2Int(10, 10), 1);

            var trail = new List<Vector2Int>();
            for (int y = 12; y <= 16; y++) trail.Add(new Vector2Int(10, y));
            for (int x = 11; x <= 16; x++) trail.Add(new Vector2Int(x, 16));
            for (int y = 15; y >= 10; y--) trail.Add(new Vector2Int(16, y));
            for (int x = 15; x >= 11; x--) trail.Add(new Vector2Int(x, 10));

            int captured = capture.ExecuteCapture(1, trail);
            Assert(captured > 20, $"TerritoryCapture: Halqa ichi to'liq egallandi ({captured} katak)");
            Assert(grid.GetOwner(13, 13) == 1, "TerritoryCapture: Halqa ichidagi (13,13) katak 1-o'yinchiga o'tdi");
        }

        private static void Test_TerritoryCapture_WaterExcluded()
        {
            byte[] mask = new byte[50];
            for (int i = 0; i < 400; i++)
            {
                int x = i % 20;
                int y = i / 20;
                if (x == 14 && y == 14) continue;
                mask[i / 8] |= (byte)(1 << (i % 8));
            }

            var grid = new GameGrid(20, 20, 1.0f, mask);
            var capture = new TerritoryCapture(grid);

            capture.SpawnInitialTerritory(1, new Vector2Int(10, 10), 1);

            var trail = new List<Vector2Int>();
            for (int y = 11; y <= 16; y++) trail.Add(new Vector2Int(10, y));
            for (int x = 11; x <= 16; x++) trail.Add(new Vector2Int(x, 16));
            for (int y = 15; y >= 10; y--) trail.Add(new Vector2Int(16, y));
            for (int x = 15; x >= 11; x--) trail.Add(new Vector2Int(x, 10));

            capture.ExecuteCapture(1, trail);

            Assert(grid.GetOwner(14, 14) == GameGrid.OWNER_WATER, "TerritoryCapture: Suv katak egallanishdan himoyalangan (OWNER_WATER)");
            Assert(grid.GetOwner(13, 13) == 1, "TerritoryCapture: Suv yonidagi quruqlik egallangan");
        }

        private static void Test_Player_TrailAndSuicide()
        {
            var grid = new GameGrid(40, 40, 1.0f);
            var capture = new TerritoryCapture(grid);

            var player = new PlayerEntity(grid, capture, new Vector2Int(20, 20), 1);

            // Tashqariga harakat (iz qoldirish)
            player.Move(new Vector2(0, 1), 0.5f);
            player.Move(new Vector2(0, 1), 0.5f);
            player.Move(new Vector2(0, 1), 0.5f);

            Assert(player.Trail.Count > 0, "PlayerEntity: Begona hududda iz (Trail) yozilmoqda");

            if (player.Trail.Count > 0)
            {
                var trailCell = player.Trail[0];
                Assert(player.CheckTrailCollision(trailCell), "PlayerEntity: O'z iziga to'qnashuv to'g'ri aniqlandi");
            }

            player.Die();
            Assert(!player.IsAlive, "PlayerEntity: O'yinchi muvaffaqiyatli o'ldi (IsAlive == false)");
        }

        private static void Test_Player_CoastlineSliding()
        {
            byte[] mask = new byte[100];
            for (int y = 0; y < 20; y++)
            {
                for (int x = 10; x < 20; x++)
                {
                    int idx = y * 20 + x;
                    mask[idx / 8] |= (byte)(1 << (idx % 8));
                }
            }

            var grid = new GameGrid(20, 20, 1.0f, mask);
            var capture = new TerritoryCapture(grid);

            var player = new PlayerEntity(grid, capture, new Vector2Int(11, 10), 1);

            Vector3 startPos = player.Position;
            player.Move(new Vector2(-1.0f, 1.0f), 0.1f);
            Vector3 newPos = player.Position;

            Vector2Int currentGrid = grid.WorldToGrid(newPos);
            Assert(grid.IsLand(currentGrid.x, currentGrid.y), "PlayerEntity (Sliding): O'yinchi suvga kirmasdan qirg'oq bo'ylab siljidi");
        }

        private static void Test_Strings_Localization()
        {
            Strings.SetLanguage("ru");
            Assert(Strings.CurrentLanguage == "ru", "Strings: Joriy til 'ru'");

            Strings.SetLanguage("uz");
            Assert(Strings.CurrentLanguage == "uz", "Strings: Til 'uz' ga o'zgardi");

            Strings.SetLanguage("unknown_lang");
            Assert(Strings.CurrentLanguage == "ru", "Strings: Noma'lum tilda 'ru' zaxira tanlandi");
        }

        private static void Test_Strings_RussianCompleteness()
        {
            Strings.SetLanguage("ru");
            string captured = Strings.T("cityCaptured");
            Assert(!string.IsNullOrEmpty(captured) && !captured.Equals("cityCaptured", StringComparison.OrdinalIgnoreCase), "Strings (RU): 'cityCaptured' kaliti ruscha matnga ega");

            string selectLang = Strings.T("selectLanguage");
            Assert(!string.IsNullOrEmpty(selectLang) && !selectLang.Equals("selectLanguage", StringComparison.OrdinalIgnoreCase), "Strings (RU): 'selectLanguage' kaliti ruscha matnga ega");

            string gameOver = Strings.T("gameOver");
            Assert(!string.IsNullOrEmpty(gameOver) && !gameOver.Equals("gameOver", StringComparison.OrdinalIgnoreCase), "Strings (RU): 'gameOver' kaliti ruscha matnga ega");
        }

        private static void Test_LanguageInfo_All15Languages()
        {
            Assert(Strings.SupportedLanguages != null && Strings.SupportedLanguages.Length == 15, "Strings: Aniq 15 ta til qo'llab-quvvatlanadi");
            bool allValid = true;
            foreach (var lang in Strings.SupportedLanguages)
            {
                if (string.IsNullOrEmpty(lang.Code) || string.IsNullOrEmpty(lang.NativeName))
                {
                    allValid = false;
                    break;
                }
            }
            Assert(allValid, "Strings: Barcha 15 ta til o'zining mahalliy (Native) nomiga ega");
        }

        private static void Test_CityNames_RussianTranslation()
        {
            Strings.SetLanguage("ru");
            CityNames.LoadData();

            string tashkent = CityNames.GetName("Tashkent");
            Assert(tashkent == "Ташкент", $"CityNames (RU): 'Tashkent' -> '{tashkent}'");

            string paris = CityNames.GetName("Paris");
            Assert(paris == "Париж", $"CityNames (RU): 'Paris' -> '{paris}'");

            string london = CityNames.GetName("London");
            Assert(london == "Лондон", $"CityNames (RU): 'London' -> '{london}'");

            string portSudan = CityNames.GetName("Port Sudan");
            Assert(portSudan == "Порт-Судан", $"CityNames (RU): 'Port Sudan' -> '{portSudan}'");
        }

        private static void Test_CitySystem_CaptureAndReward()
        {
            var grid = new GameGrid(30, 30, 1.0f);
            var citySystem = new CitySystem(grid);
            var capture = new TerritoryCapture(grid, citySystem);

            citySystem.AddCity("Port Sudan", "SD", 15, 15, 500000, false);
            Assert(citySystem.Cities.Count == 1, "CitySystem: Shahar muvaffaqiyatli qo'shildi");

            int notifiedCount = 0;
            int totalReward = 0;
            CityData capturedCity = null;

            citySystem.OnCityCaptured += (city, capturer, reward) =>
            {
                notifiedCount++;
                totalReward += reward;
                capturedCity = city;
            };

            // Shaharni egallash
            capture.SpawnInitialTerritory(1, new Vector2Int(15, 15), 1);
            citySystem.CheckCityCapture(1, 15, 15);

            Assert(notifiedCount == 1, "CitySystem: Shahar egallanganda hodisa 1 marta chaqirildi");
            Assert(totalReward > 0, $"CitySystem: Egallash mukofoti hisoblandi ({totalReward} tanga)");
            Assert(capturedCity != null && capturedCity.OwnerId == 1, "CitySystem: Shahar egasi 1-o'yinchiga o'tdi");

            // Qayta tekshirganda takroriy hodisa chaqirilmasligi kerak (Deduplication)
            citySystem.CheckCityCapture(1, 15, 15);
            Assert(notifiedCount == 1, "CitySystem: Takroriy egallashda hodisa qayta chaqirilmadi (Deduplication)");
        }

        private static void Test_TrailDanger_ChasingAndSurvival()
        {
            var grid = new GameGrid(50, 50, 1.0f);
            var capture = new TerritoryCapture(grid);
            var player = new PlayerEntity(grid, capture, new Vector2Int(20, 20), 1);

            // O'yinchi spawn hududidan chiqadi (spawn radiusi 2, ya'ni y=23 ga chiqadi)
            for (int i = 0; i < 5; i++)
            {
                player.Move(new Vector2(0, 1), 0.2f);
            }
            Assert(player.Trail.Count > 0, "TrailDanger: O'yinchi iz qoldirdi");

            Vector2Int hitCell = player.Trail[0];
            bool dangerStarted = false;
            player.OnDangerStarted += (p, attacker) => { dangerStarted = true; };

            player.TriggerTrailDanger(2, hitCell);
            Assert(dangerStarted, "TrailDanger: Izga tegilganda xavf to'lqini boshlandi");
            Assert(player.Danger != null, "TrailDanger: Faol xavf mavjud");

            // O'yinchi zudlik bilan o'z hududiga qaytadi (yon tomondan o'z mulkiga kiradi)
            bool escaped = false;
            player.OnDangerEscaped += (p) => { escaped = true; };

            // Yon tomonga va pastga qarab o'z hududiga (x=19, y=21) yuradi
            player.Move(new Vector2(-1, 0), 0.2f);
            for (int i = 0; i < 5; i++)
            {
                player.Move(new Vector2(0, -1), 0.2f);
            }

            Assert(player.Danger == null, "TrailDanger: O'z hududiga kirganda xavf bekor qilindi (Danger == null)");
            Assert(escaped, "TrailDanger: OnDangerEscaped hodisasi chaqirildi");
            Assert(player.IsAlive, "TrailDanger: Xavfdan o'z hududiga qochib qutulgan o'yinchi tirik qoldi");
        }

        private static void Test_TrailDanger_CatchAndDeath()
        {
            var grid = new GameGrid(50, 50, 1.0f);
            var capture = new TerritoryCapture(grid);
            var player = new PlayerEntity(grid, capture, new Vector2Int(20, 20), 1);

            for (int i = 0; i < 10; i++)
            {
                player.Move(new Vector2(0, 1), 0.2f);
            }

            Vector2Int hitCell = player.Trail[0];
            player.TriggerTrailDanger(2, hitCell);

            // Vaqt o'tadi va xavf to'lqini o'yinchiga yetib boradi
            player.UpdateDanger(2.0f); // 2 sekund (30 katak/sek = 60 katak)

            Assert(!player.IsAlive, "TrailDanger: Xavf to'lqini yetib kelganda o'yinchi halok bo'ldi");
            Assert(player.Danger == null, "TrailDanger: O'limdan so'ng xavf holati tozalandi");
        }

        private static void Test_VersionConfig_FormatAndValidation()
        {
            Assert(VersionConfig.IsValidVersion("1.00.000"), "VersionConfig: '1.00.000' formati to'g'ri");
            Assert(VersionConfig.IsValidVersion("1.00.001"), "VersionConfig: '1.00.001' formati to'g'ri");
            Assert(VersionConfig.IsValidVersion("2.15.042"), "VersionConfig: '2.15.042' formati to'g'ri");
            Assert(!VersionConfig.IsValidVersion("1.0.0"), "VersionConfig: '1.0.0' rad etildi (2 va 3 xonali talab)");
            Assert(!VersionConfig.IsValidVersion("v1.00.000"), "VersionConfig: 'v' prefiksi rad etildi");
            Assert(!VersionConfig.IsValidVersion(""), "VersionConfig: Bo'sh matn rad etildi");
            Assert(!VersionConfig.IsValidVersion("1.00.000-alpha"), "VersionConfig: Qo'shimcha belgilar rad etildi");

            var (maj, min, patch) = VersionConfig.ParseVersion("1.00.000");
            Assert(maj == 1 && min == 0 && patch == 0, "VersionConfig: Parse '1.00.000' -> (1, 0, 0)");
        }

        private static void Test_VersionConfig_BumpRules()
        {
            string p1 = VersionConfig.BumpPatch("1.00.000");
            Assert(p1 == "1.00.001", "VersionConfig: BumpPatch('1.00.000') -> '1.00.001'");

            string p2 = VersionConfig.BumpPatch("1.00.009");
            Assert(p2 == "1.00.010", "VersionConfig: BumpPatch('1.00.009') -> '1.00.010'");

            string m1 = VersionConfig.BumpMinor("1.00.005");
            Assert(m1 == "1.01.000", "VersionConfig: BumpMinor('1.00.005') -> '1.01.000' (patch=000 ga tiklandi)");

            string maj1 = VersionConfig.BumpMajor("1.02.045");
            Assert(maj1 == "2.00.000", "VersionConfig: BumpMajor('1.02.045') -> '2.00.000' (minor va patch nollashtirildi)");
        }

        private static void Test_VersionConfig_AboutDisplay()
        {
            string about = VersionConfig.GetAboutDisplay();
            Assert(about.Contains(VersionConfig.CURRENT_VERSION), $"VersionConfig: About matnida joriy versiya mavjud ('{VersionConfig.CURRENT_VERSION}')");
            Assert(about.Contains(VersionConfig.PACKAGE_NAME), "VersionConfig: About matnida paket nomi mavjud ('com.shogoyos.colorland3d')");
        }

        private static void Test_SaveManager_DefaultsAndLifecycle()
        {
            var def = SaveManager.CreateDefault();
            Assert(def.SchemaVersion == 1, "SaveManager: Boshlang'ich sxema versiyasi 1");
            Assert(def.Coins == 1000, "SaveManager: Boshlang'ich tangalar soni 1000");
            Assert(def.Gems == 50, "SaveManager: Boshlang'ich qimmatbaho toshlar soni 50");
            Assert(def.UnlockedSkins.Contains("default"), "SaveManager: Boshlang'ich liboslar ichida 'default' mavjud");
            Assert(def.SelectedLanguage == "ru", "SaveManager: Boshlang'ich tanlangan til 'ru'");
        }

        private static void Test_SaveManager_ExportImport()
        {
            SaveManager.ResetToDefaults();
            SaveManager.Current.Coins = 2500;
            SaveManager.Current.Gems = 99;
            string backup = SaveManager.ExportBackup();
            Assert(!string.IsNullOrEmpty(backup), "SaveManager: Zaxira nusxa JSON eksport qilindi");

            SaveManager.ResetToDefaults();
            Assert(SaveManager.Current.Coins == 1000, "SaveManager: Reset qilindi, tangalar 1000 ga tushdi");

            bool ok = SaveManager.ImportBackup(backup);
            Assert(ok, "SaveManager: Zaxira nusxa muvaffaqiyatli import qilindi");
            Assert(SaveManager.Current.Coins == 2500, "SaveManager: Tiklangan tangalar soni 2500 ga qaytdi");
            Assert(SaveManager.Current.Gems == 99, "SaveManager: Tiklangan toshlar soni 99 ga qaytdi");
        }
    }
}
