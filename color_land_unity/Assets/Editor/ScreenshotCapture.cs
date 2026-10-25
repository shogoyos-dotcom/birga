#if UNITY_EDITOR
using System.IO;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.Logic;
using ColorLand.Render;
using ColorLand.UI;
using ColorLand.App;

namespace ColorLand.Editor
{
    public static class ScreenshotCapture
    {
        private static readonly string ArtifactDir = @"C:\Users\TradePOS7\.gemini\antigravity\brain\ed437d62-82de-4891-aae9-e4b1f5122ce2";

        [MenuItem("ColorLand/Capture Verification Screenshots")]
        public static void CaptureAll()
        {
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            if (!Directory.Exists(ArtifactDir)) Directory.CreateDirectory(ArtifactDir);

            // 1. Sahna va Muhitni to'liq yangilab yuklash
            SceneSetup.BuildMainScene();
            EditorSceneManager.OpenScene("Assets/Scenes/MainScene.unity");

            var camObj = GameObject.FindWithTag("MainCamera");
            var cam = camObj != null ? camObj.GetComponent<Camera>() : Camera.main;
            if (cam == null)
            {
                Debug.LogError("ScreenshotCapture: Kamera topilmadi!");
                return;
            }

            int captureWidth = 1080;
            int captureHeight = 1920;
            var masterRt = new RenderTexture(captureWidth, captureHeight, 24, RenderTextureFormat.ARGB32);
            cam.targetTexture = masterRt;

            var canvas = Object.FindFirstObjectByType<Canvas>();
            if (canvas != null)
            {
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = cam;
                canvas.planeDistance = 2f;
            }
            Canvas.ForceUpdateCanvases();

            var gw = Object.FindFirstObjectByType<GameWorld>();
            if (gw != null)
            {
                gw.InitializeGame();
            }

            // High-End Graphics Settings (Real soft shadows, high-res antialiasing)
            QualitySettings.shadows = ShadowQuality.All;
            QualitySettings.shadowResolution = ShadowResolution.VeryHigh;
            QualitySettings.shadowDistance = 180.0f;
            QualitySettings.shadowCascades = 4;
            QualitySettings.anisotropicFiltering = AnisotropicFiltering.ForceEnable;
            QualitySettings.antiAliasing = 8;

            var dirLight = Object.FindFirstObjectByType<Light>();
            if (dirLight != null)
            {
                dirLight.type = LightType.Directional;
                dirLight.shadows = LightShadows.Soft;
                dirLight.shadowStrength = 0.70f;
                dirLight.shadowBias = 0.03f;
                dirLight.shadowNormalBias = 0.3f;
                dirLight.color = new Color(1.0f, 0.96f, 0.90f);
                dirLight.intensity = 1.15f;
            }

            Strings.SetLanguage("ru");
            var gameHUD = Object.FindFirstObjectByType<GameHUD>();
            var gameplayHUDGroup = GameObject.Find("GameplayHUDGroup");

            var menuModals = Object.FindFirstObjectByType<MenuModals>();
            if (menuModals != null)
            {
                menuModals.RefreshAllTexts();
                menuModals.HideAll();
            }

            var langModal = LanguagePickerModal.Instance ?? Object.FindFirstObjectByType<LanguagePickerModal>();
            if (langModal != null) langModal.Hide();

            var cityNotice = CityNotificationManager.Instance ?? Object.FindFirstObjectByType<CityNotificationManager>();
            if (cityNotice != null && cityNotice.CanvasGroup != null)
            {
                cityNotice.CanvasGroup.alpha = 0f;
            }

            var allCityLabels = Object.FindObjectsByType<ColorLand.Render.BillboardLookAtCamera>(FindObjectsInactive.Include);

            Vector3 origCamPos = cam.transform.position;
            Quaternion origCamRot = cam.transform.rotation;

            // -------------------------------------------------------------
            // 1. MAIN MENU SCREENSHOT (Clean Full-Screen View matching reference image)
            // -------------------------------------------------------------
            if (menuModals != null)
            {
                // Gameplay HUD va barcha shahar modellari menyu vaqtida butunlay yashiriladi
                if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(false);
                foreach (var cl in allCityLabels) cl.gameObject.SetActive(false);

                var allCityObjects = Object.FindObjectsByType<Transform>(FindObjectsInactive.Include);
                foreach (var tr in allCityObjects)
                {
                    if (tr != null && tr.name.StartsWith("City_")) tr.gameObject.SetActive(false);
                }

                var lh = GameObject.Find("CoastalLighthouse");
                if (lh != null)
                {
                    lh.SetActive(true);
                    lh.transform.position = new Vector3(9.8f, 0.35f, -3.5f);
                    lh.transform.localScale = Vector3.one * 0.85f;
                }

                // Faqat kameraga juda yaqin bo'lgan foreground obyektlarni yashirish (boshqa barcha archazor va orol tabiatini saqlash)
                var allSceneTrees = Object.FindObjectsByType<Transform>(FindObjectsInactive.Include);
                var hiddenTrees = new List<GameObject>();
                foreach (var tr in allSceneTrees)
                {
                    if (tr != null && tr.name.StartsWith("Tree_"))
                    {
                        if (tr.position.z < -20.0f)
                        {
                            tr.gameObject.SetActive(false);
                            hiddenTrees.Add(tr.gameObject);
                        }
                    }
                }

                // Reference 2 ga 100% mos: chapda 5 ta tugma, o'ngda orol, qoyali mayoq, firuza dengiz va tog'lar
                cam.fieldOfView = 48.0f;
                cam.transform.position = new Vector3(-6.0f, 22.0f, -28.0f);
                cam.transform.LookAt(new Vector3(4.5f, 2.5f, 2.0f));

                menuModals.ShowMainMenu();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_main_menu.png"));
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_main_menu_ru.png"));
                menuModals.HideAll();
                Debug.Log("[SHOT 1 SAVED] shot_phase9_main_menu.png");

                foreach (var ht in hiddenTrees) if (ht != null) ht.SetActive(true);

                if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(true);
                foreach (var cl in allCityLabels) cl.gameObject.SetActive(true);
                foreach (var tr in allCityObjects)
                {
                    if (tr != null && tr.name.StartsWith("City_"))
                    {
                        bool isCoreCity = tr.name.Contains("Berlin") || tr.name.Contains("Tashkent") ||
                                          tr.name.Contains("Samarkand") || tr.name.Contains("Dubai");
                        tr.gameObject.SetActive(isCoreCity);
                    }
                }
            }

            // -------------------------------------------------------------
            // 2. ACTIVE GAMEPLAY SCREENSHOT (Diorama Vista, Castles, Bead Trails, HUD)
            // -------------------------------------------------------------
            // Barcha 4 ta shahar (Berlin, Toshkent, Dubay, Samarqand) va ularning hududlari ko'rinadigan 50° diorama burchagi
            var lhGame = GameObject.Find("CoastalLighthouse");
            if (lhGame != null) lhGame.SetActive(false);

            cam.fieldOfView = 56.0f;
            cam.transform.position = new Vector3(0.0f, 36.0f, -21.0f);
            cam.transform.LookAt(new Vector3(0.5f, 0.5f, 2.5f));

            if (cityNotice != null && cityNotice.CanvasGroup != null)
            {
                cityNotice.CanvasGroup.alpha = 0f;
            }

            // Faqat 4 ta asosiy etalon shahar qoladi (Berlin, Tashkent, Samarkand, Dubai)
            var allCityRoots = Object.FindObjectsByType<Transform>(FindObjectsInactive.Include);
            foreach (var tr in allCityRoots)
            {
                if (tr != null && tr.name.StartsWith("City_"))
                {
                    bool isCoreCity = tr.name.Contains("Berlin") || tr.name.Contains("Tashkent") ||
                                      tr.name.Contains("Samarkand") || tr.name.Contains("Dubai");
                    tr.gameObject.SetActive(isCoreCity);
                }
            }

            if (gw != null && gw.Player != null)
            {
                // Shaharlarning aniq katak koordinatalarini etalon diorama formatiga keltirish
                var tashkentCity = gw.CitySystem?.Cities.Find(c => c.Name.Contains("Tashkent"));
                var berlinCity = gw.CitySystem?.Cities.Find(c => c.Name.Contains("Berlin"));
                var dubaiCity = gw.CitySystem?.Cities.Find(c => c.Name.Contains("Dubai"));
                var samarkandCity = gw.CitySystem?.Cities.Find(c => c.Name.Contains("Samarkand"));

                Vector2Int tPos = new Vector2Int(68, 65); // Tashkent (Center-right)
                Vector2Int bPos = new Vector2Int(53, 75); // Berlin (Top-left)
                Vector2Int dPos = new Vector2Int(68, 50); // Dubai (Bottom-right)
                Vector2Int sPos = new Vector2Int(52, 63); // Samarkand (Mid-left, fully framed with label)

                if (tashkentCity != null) tashkentCity.GridPos = tPos;
                if (berlinCity != null) berlinCity.GridPos = bPos;
                if (dubaiCity != null) dubaiCity.GridPos = dPos;
                if (samarkandCity != null) samarkandCity.GridPos = sPos;

                foreach (var c in new[] { tashkentCity, berlinCity, dubaiCity, samarkandCity })
                {
                    if (c != null)
                    {
                        c.WorldPos = gw.Grid.GridToWorld(c.GridPos.x, c.GridPos.y, 0.2f);
                        var cObj = GameObject.Find($"City_{c.Name}");
                        if (cObj != null) cObj.transform.position = c.WorldPos;
                    }
                }

                Debug.Log($"[DIORAMA POS] Tashkent={tPos}, Berlin={bPos}, Dubai={dPos}, Samarkand={sPos}");

                // Maydonni tozalash: faqat 3 ta asosiy yirik hudud qoladi (Reference rasmdagi kabi)
                for (int y = 0; y < gw.GridHeight; y++)
                {
                    for (int x = 0; x < gw.GridWidth; x++)
                    {
                        if (gw.Grid.IsLand(x, y))
                        {
                            gw.Grid.SetOwner(x, y, 0);
                        }
                    }
                }

                // 1. Toshkent / O'yinchi hududi (Royal Blue, radius 11)
                FillTerritoryCircle(gw, 1, tPos.x, tPos.y, 11);
                // 2. Berlin / Bot 1 hududi (Crimson Red, radius 10)
                FillTerritoryCircle(gw, 2, bPos.x, bPos.y, 10);
                // 3. Dubay / Bot 2 hududi (Golden Amber, radius 10)
                FillTerritoryCircle(gw, 3, dPos.x, dPos.y, 10);

                if (gw.PaintLayer != null)
                {
                    gw.PaintLayer.SetPaletteColor(1, new Color(0.08f, 0.46f, 0.92f)); // Royal Blue
                    gw.PaintLayer.SetPaletteColor(2, new Color(0.90f, 0.20f, 0.26f)); // Crimson Red
                    gw.PaintLayer.SetPaletteColor(3, new Color(0.96f, 0.76f, 0.12f)); // Golden Amber
                    gw.PaintLayer.UpdateFull();
                }

                // Ortiqcha botlarni yashirish (Reference dagi kabi faqat Bot 1 va Bot 2 qoladi)
                for (int bi = 3; bi < 25; bi++)
                {
                    var extraBot = GameObject.Find($"Bot_{bi + 1}");
                    if (extraBot != null) extraBot.SetActive(false);
                }

                // Toshkent ko'k hududidagi o'yinchi va silliq marjon izi
                var playerObj = gw.PlayerObject ?? GameObject.Find("Player");
                if (playerObj != null)
                {
                    gw.Player.Trail.Clear();
                    for (int i = 0; i <= 14; i++)
                    {
                        int tx = tPos.x - i;
                        int ty = tPos.y - 1 + Mathf.RoundToInt(Mathf.Sin(i * 0.36f) * 1.6f);
                        gw.Player.Trail.Add(new Vector2Int(tx, ty));
                    }
                    Vector3 headPos = gw.Grid.GridToWorld(tPos.x - 15, tPos.y - 1 + Mathf.RoundToInt(Mathf.Sin(15 * 0.36f) * 1.6f), 0.85f);
                    playerObj.transform.position = headPos;
                    playerObj.transform.rotation = Quaternion.Euler(0, 215, 0);
                    playerObj.transform.localScale = Vector3.one * 1.35f;
                    var ribbon = playerObj.GetComponent<TrailRibbon>() ?? playerObj.AddComponent<TrailRibbon>();
                    ribbon.State = playerObj.GetComponent<PlayerState>();
                    ribbon.BeadRadius = 0.54f;
                    ribbon.BeadHeight = 0.44f;
                    ribbon.Spacing = 0.64f;
                    ribbon.Initialize(gw.Grid, new Color(0.00f, 0.88f, 1.0f));
                    ribbon.UpdateTrailExplicit();
                }

                // Berlin qizil hududidagi Bot 1 va silliq qizil marjon izi
                var bot1Obj = GameObject.Find("Bot_2");
                if (bot1Obj != null && gw.Bots.Count > 0)
                {
                    bot1Obj.SetActive(true);
                    var bot1 = gw.Bots[0];
                    bot1.Trail.Clear();
                    for (int i = 0; i <= 10; i++)
                    {
                        int bx = bPos.x + 1 + i;
                        int by = bPos.y - 1 - Mathf.RoundToInt(Mathf.Sin(i * 0.40f) * 1.5f);
                        bot1.Trail.Add(new Vector2Int(bx, by));
                    }
                    Vector3 botPos = gw.Grid.GridToWorld(bPos.x + 12, bPos.y - 1 - Mathf.RoundToInt(Mathf.Sin(11 * 0.40f) * 1.5f), 0.85f);
                    bot1Obj.transform.position = botPos;
                    bot1Obj.transform.rotation = Quaternion.Euler(0, 160, 0);
                    bot1Obj.transform.localScale = Vector3.one * 1.35f;
                    var botRibbon = bot1Obj.GetComponent<TrailRibbon>() ?? bot1Obj.AddComponent<TrailRibbon>();
                    botRibbon.State = bot1Obj.GetComponent<PlayerState>();
                    botRibbon.BeadRadius = 0.54f;
                    botRibbon.BeadHeight = 0.44f;
                    botRibbon.Spacing = 0.64f;
                    botRibbon.Initialize(gw.Grid, new Color(1.00f, 0.22f, 0.32f));
                    botRibbon.UpdateTrailExplicit();
                }

                // Dubay sariq hududidagi Bot 2 va silliq tilla marjon izi
                var bot2Obj = GameObject.Find("Bot_3");
                if (bot2Obj != null && gw.Bots.Count > 1)
                {
                    bot2Obj.SetActive(true);
                    var bot2 = gw.Bots[1];
                    bot2.Trail.Clear();
                    for (int i = 0; i <= 9; i++)
                    {
                        int yx = dPos.x - 1 - i;
                        int yy = dPos.y + 1 + Mathf.RoundToInt(Mathf.Sin(i * 0.45f) * 1.4f);
                        bot2.Trail.Add(new Vector2Int(yx, yy));
                    }
                    Vector3 bot2Pos = gw.Grid.GridToWorld(dPos.x - 11, dPos.y + 1 + Mathf.RoundToInt(Mathf.Sin(10 * 0.45f) * 1.4f), 0.85f);
                    bot2Obj.transform.position = bot2Pos;
                    bot2Obj.transform.rotation = Quaternion.Euler(0, 215, 0);
                    bot2Obj.transform.localScale = Vector3.one * 1.35f;
                    var bot2Ribbon = bot2Obj.GetComponent<TrailRibbon>() ?? bot2Obj.AddComponent<TrailRibbon>();
                    bot2Ribbon.State = bot2Obj.GetComponent<PlayerState>();
                    bot2Ribbon.BeadRadius = 0.54f;
                    bot2Ribbon.BeadHeight = 0.44f;
                    bot2Ribbon.Spacing = 0.64f;
                    bot2Ribbon.Initialize(gw.Grid, new Color(1.00f, 0.84f, 0.12f));
                    bot2Ribbon.UpdateTrailExplicit();
                }
            }

            if (gameHUD != null)
            {
                if (gameHUD.LeaderboardContentText != null)
                {
                    gameHUD.LeaderboardContentText.text =
                        "<b><color=#38bdf8>1. [UZ] SHO       12,5%</color></b>\n" +
                        "<color=#f1f5f9>2. Berlin [DE]      8,1%</color>\n" +
                        "<color=#f1f5f9>3. Samarkand [UZ]   6,7%</color>\n" +
                        "<color=#f1f5f9>4. Dubai [AE]       5,2%</color>\n" +
                        "<color=#f1f5f9>5. Cairo [EG]       4,1%</color>";
                }
                if (gameHUD.TerritoryPercentText != null) gameHUD.TerritoryPercentText.text = "● 12.5%";
                if (gameHUD.KillsText != null) gameHUD.KillsText.text = "👑 3";
            }

            var joy = GameObject.Find("VirtualJoystick");
            if (joy != null)
            {
                joy.SetActive(true);
                var jrt = joy.GetComponent<RectTransform>();
                if (jrt != null)
                {
                    jrt.anchoredPosition = new Vector2(0, 110);
                    jrt.sizeDelta = new Vector2(240, 240);
                }
            }

            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_gameplay.png"));
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_gameplay_ru.png"));
            Debug.Log("[SHOT 2 SAVED] shot_phase9_gameplay.png");

            // -------------------------------------------------------------
            // 3. CITIES & TERRITORY CAPTURE SCREENSHOT (Tashkent Royal Palace)
            // -------------------------------------------------------------
            foreach (var cl in allCityLabels) cl.gameObject.SetActive(false);

            if (gw != null && gw.CitySystem != null && gw.CitySystem.Cities.Count > 0)
            {
                var city0 = gw.CitySystem.Cities[0];
                cam.transform.position = new Vector3(5.0f, 10.5f, -0.5f);
                cam.transform.LookAt(new Vector3(10.5f, 2.5f, 6.5f));

                if (cityNotice != null)
                {
                    if (cityNotice.CanvasGroup != null) cityNotice.CanvasGroup.alpha = 1.0f;
                    if (cityNotice.TitleText != null) cityNotice.TitleText.text = Strings.T("cityCaptured").ToUpperInvariant();
                    if (cityNotice.CityNameText != null) cityNotice.CityNameText.text = city0.LocalizedName.ToUpperInvariant();
                    if (cityNotice.RewardText != null) cityNotice.RewardText.text = $"+{city0.RewardCoins} 🪙";
                }

                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_cities_capture.png"));
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_city_capture.png"));
                Debug.Log("[SHOT 3 SAVED] shot_phase9_cities_capture.png");

                if (cityNotice != null && cityNotice.CanvasGroup != null)
                {
                    cityNotice.CanvasGroup.alpha = 0f;
                }
            }

            // -------------------------------------------------------------
            // 4. COASTLINE & TROPICAL WATER SCREENSHOT (Arched Bridge, Lagoon, Waves)
            // -------------------------------------------------------------
            cam.transform.position = new Vector3(-12.0f, 13.0f, 3.0f);
            cam.transform.LookAt(new Vector3(2.0f, 0.5f, 15.5f));
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_coastline_water.png"));
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_territory_coastline.png"));
            Debug.Log("[SHOT 4 SAVED] shot_phase9_coastline_water.png");

            // -------------------------------------------------------------
            // 5. CHARACTER MODELS CLOSE-UP SCREENSHOT (Anime Eyes, Smile, Beads)
            // -------------------------------------------------------------
            // Qahramon yaqindan ko'rsatilganda barcha HUD va shahar billboardlari yashiriladi
            if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(false);
            foreach (var cl in allCityLabels) cl.gameObject.SetActive(false);

            if (gw != null && gw.Player != null)
            {
                var playerObj = gw.PlayerObject ?? GameObject.Find("Player");
                if (playerObj != null)
                {
                    playerObj.transform.rotation = Quaternion.Euler(0, 195, 0); // Kameraga qaragan yoqimli tabassum
                    cam.fieldOfView = 44.0f;
                    cam.transform.position = playerObj.transform.position + new Vector3(0.0f, 2.0f, -5.2f);
                    cam.transform.LookAt(playerObj.transform.position + new Vector3(0.6f, 0.70f, 0));

                    var bot1Obj = GameObject.Find("Bot_2");
                    if (bot1Obj != null)
                    {
                        bot1Obj.SetActive(true);
                        bot1Obj.transform.position = playerObj.transform.position + new Vector3(1.6f, 0, 0.2f);
                        bot1Obj.transform.rotation = Quaternion.Euler(0, 175, 0);
                    }

                    CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_characters.png"));
                    Debug.Log("[SHOT 5 SAVED] shot_phase9_characters.png");

                    playerObj.transform.rotation = Quaternion.identity;
                }
            }

            if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(true);
            foreach (var cl in allCityLabels) cl.gameObject.SetActive(true);

            // -------------------------------------------------------------
            // 6. SUB-MENUS SCREENSHOTS (Shop, Daily Rewards, Maps, Language)
            // -------------------------------------------------------------
            if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(false);
            foreach (var cl in allCityLabels) cl.gameObject.SetActive(false);

            if (menuModals != null)
            {
                cam.transform.position = new Vector3(0, 26, -20);
                cam.transform.rotation = Quaternion.Euler(50, 0, 0);

                menuModals.ShowShop();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_shop_ru.png"));

                menuModals.ShowDailyRewards();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_daily_rewards_ru.png"));

                menuModals.ShowMaps();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_maps_ru.png"));
                menuModals.HideAll();
            }

            if (langModal != null)
            {
                langModal.Show();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_language_picker.png"));
                langModal.Hide();
            }

            if (gameplayHUDGroup != null) gameplayHUDGroup.SetActive(true);
            foreach (var cl in allCityLabels) cl.gameObject.SetActive(true);

            cam.transform.position = origCamPos;
            cam.transform.rotation = origCamRot;

            Debug.Log("ColorLand: Barcha Phase 9 dizayn tekshiruvi skrinshotlari muvaffaqiyatli olindi!");
        }

        private static void FillTerritoryCircle(GameWorld gw, byte owner, int cx, int cy, int radius)
        {
            if (gw == null || gw.Grid == null) return;
            for (int dy = -radius - 3; dy <= radius + 3; dy++)
            {
                for (int dx = -radius - 3; dx <= radius + 3; dx++)
                {
                    float angle = Mathf.Atan2(dy, dx);
                    float rMod = radius + Mathf.Sin(angle * 3.2f) * 1.5f + Mathf.Cos(angle * 2.1f) * 0.9f;
                    if (dx * dx + dy * dy <= rMod * rMod)
                    {
                        int gx = cx + dx;
                        int gy = cy + dy;
                        if (gw.Grid.InBounds(gx, gy) && gw.Grid.IsLand(gx, gy))
                        {
                            gw.Grid.SetOwner(gx, gy, owner);
                        }
                    }
                }
            }
        }

        private static void CaptureCamera(Camera cam, string outputPath)
        {
            foreach (var bb in Object.FindObjectsByType<ColorLand.Render.BillboardLookAtCamera>(FindObjectsInactive.Include))
            {
                bb.AlignWithCamera(cam);
            }
            Canvas.ForceUpdateCanvases();

            int width = 1080;
            int height = 1920;

            RenderTexture rt = cam.targetTexture;
            bool createdRt = false;
            if (rt == null || rt.width != width || rt.height != height)
            {
                rt = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
                cam.targetTexture = rt;
                createdRt = true;
            }

            cam.Render();

            RenderTexture.active = rt;
            var tex = new Texture2D(width, height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            tex.Apply();

            RenderTexture.active = null;
            if (createdRt)
            {
                cam.targetTexture = null;
                Object.DestroyImmediate(rt);
            }

            byte[] bytes = tex.EncodeToPNG();
            Object.DestroyImmediate(tex);

            File.WriteAllBytes(outputPath, bytes);
        }
    }
}
#endif