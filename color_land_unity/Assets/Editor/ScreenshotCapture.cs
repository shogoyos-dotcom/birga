#if UNITY_EDITOR
using System.IO;
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
            if (!Directory.Exists(ArtifactDir)) Directory.CreateDirectory(ArtifactDir);

            // Sahna yuklash
            EditorSceneManager.OpenScene("Assets/Scenes/MainScene.unity");

            var camObj = GameObject.FindWithTag("MainCamera");
            var cam = camObj != null ? camObj.GetComponent<Camera>() : Camera.main;
            if (cam == null)
            {
                Debug.LogError("ScreenshotCapture: Kamera topilmadi!");
                return;
            }

            var canvas = Object.FindFirstObjectByType<Canvas>();
            if (canvas != null)
            {
                canvas.renderMode = RenderMode.ScreenSpaceCamera;
                canvas.worldCamera = cam;
                canvas.planeDistance = 2f;
            }

            var gw = Object.FindFirstObjectByType<GameWorld>();
            if (gw != null)
            {
                gw.InitializeGame();
            }

            Strings.SetLanguage("ru");
            if (GameHUD.Instance != null) GameHUD.Instance.OnLanguageChanged();
            var menuModals = Object.FindFirstObjectByType<MenuModals>();
            if (menuModals != null)
            {
                menuModals.RefreshAllTexts();
                menuModals.HideAll();
            }

            var langModal = LanguagePickerModal.Instance ?? Object.FindFirstObjectByType<LanguagePickerModal>();
            if (langModal != null) langModal.Hide();

            Vector3 origCamPos = cam.transform.position;
            Quaternion origCamRot = cam.transform.rotation;

            // -------------------------------------------------------------
            // 1. MAIN MENU SCREENSHOT (Scenic Diorama Vista + Polished UI)
            // -------------------------------------------------------------
            if (menuModals != null)
            {
                cam.transform.position = new Vector3(0, 26, -20);
                cam.transform.rotation = Quaternion.Euler(50, 0, 0);

                menuModals.ShowMainMenu();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_main_menu.png"));
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_main_menu_ru.png"));
                menuModals.HideAll();
                Debug.Log("[SHOT 1 SAVED] shot_phase9_main_menu.png");
            }

            // -------------------------------------------------------------
            // 2. ACTIVE GAMEPLAY SCREENSHOT (Heroic Character, Bead Trails, HUD)
            // -------------------------------------------------------------
            cam.transform.position = new Vector3(0, 22.0f, -15.5f);
            cam.transform.rotation = Quaternion.Euler(52, 0, 0);

            if (gw != null && gw.Player != null)
            {
                // Give player some smooth captured territory
                gw.CaptureSystem.SpawnInitialTerritory(1, new Vector2Int(gw.GridWidth / 2, gw.GridHeight / 2), 6);
                if (gw.PaintLayer != null) gw.PaintLayer.UpdateFull();

                // Add active glossy bead trail trailing behind the ball matching reference image!
                var playerEntity = gw.Player;
                var playerObj = GameObject.Find("Player");
                if (playerObj != null)
                {
                    Vector2Int center = new Vector2Int(gw.GridWidth / 2, gw.GridHeight / 2);
                    playerEntity.Trail.Clear();
                    for (int i = 0; i <= 8; i++)
                    {
                        int tx = center.x - 4 + i;
                        int ty = center.y + 6 + Mathf.RoundToInt(Mathf.Sin(i * 0.45f) * 2.2f);
                        playerEntity.Trail.Add(new Vector2Int(tx, ty));
                    }
                    Vector3 headPos = gw.Grid.GridToWorld(center.x + 5, center.y + 6 + Mathf.RoundToInt(Mathf.Sin(9 * 0.45f) * 2.2f), 0.85f);
                    playerObj.transform.position = headPos;
                    var ribbon = playerObj.GetComponent<TrailRibbon>();
                    if (ribbon != null) ribbon.UpdateTrailExplicit();
                }
            }

            if (GameHUD.Instance != null)
            {
                GameHUD.Instance.UpdateHUDExplicit();
            }

            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_gameplay.png"));
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_gameplay_ru.png"));
            Debug.Log("[SHOT 2 SAVED] shot_phase9_gameplay.png");

            // -------------------------------------------------------------
            // 3. CITIES & TERRITORY CAPTURE SCREENSHOT (Small, Medium, Large)
            // -------------------------------------------------------------
            if (gw != null && gw.CitySystem != null && gw.CitySystem.Cities.Count > 0)
            {
                var city0 = gw.CitySystem.Cities[0];
                cam.transform.position = city0.WorldPos + new Vector3(0, 16.0f, -12.0f);
                cam.transform.LookAt(city0.WorldPos + new Vector3(0, 2.0f, 0));

                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_cities_capture.png"));
                Debug.Log("[SHOT 3 SAVED] shot_phase9_cities_capture.png");

                // City notification card
                var cityNotice = CityNotificationManager.Instance ?? Object.FindFirstObjectByType<CityNotificationManager>();
                if (cityNotice != null)
                {
                    if (cityNotice.CanvasGroup != null) cityNotice.CanvasGroup.alpha = 1.0f;
                    if (cityNotice.TitleText != null) cityNotice.TitleText.text = Strings.T("cityCaptured").ToUpperInvariant();
                    if (cityNotice.CityNameText != null) cityNotice.CityNameText.text = city0.LocalizedName.ToUpperInvariant();
                    if (cityNotice.RewardText != null) cityNotice.RewardText.text = $"+{city0.RewardCoins} 🪙";
                    CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_city_capture.png"));
                    if (cityNotice.CanvasGroup != null) cityNotice.CanvasGroup.alpha = 0f;
                }
            }

            // -------------------------------------------------------------
            // 4. COASTLINE & TROPICAL WATER SCREENSHOT
            // -------------------------------------------------------------
            cam.transform.position = new Vector3(-35, 14.0f, -38);
            cam.transform.rotation = Quaternion.Euler(38, 45, 0);
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_coastline_water.png"));
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_territory_coastline.png"));
            Debug.Log("[SHOT 4 SAVED] shot_phase9_coastline_water.png");

            // -------------------------------------------------------------
            // 5. CHARACTER MODELS CLOSE-UP SCREENSHOT
            // -------------------------------------------------------------
            if (gw != null && gw.Player != null)
            {
                var playerObj = GameObject.Find("Player");
                if (playerObj != null)
                {
                    cam.transform.position = playerObj.transform.position + new Vector3(0, 3.2f, -5.2f);
                    cam.transform.LookAt(playerObj.transform.position + new Vector3(0, 0.95f, 0));
                    CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_phase9_characters.png"));
                    Debug.Log("[SHOT 5 SAVED] shot_phase9_characters.png");
                }
            }

            // -------------------------------------------------------------
            // 6. SUB-MENUS SCREENSHOTS (Shop, Daily Rewards, Maps, Language)
            // -------------------------------------------------------------
            if (menuModals != null)
            {
                cam.transform.position = new Vector3(0, 26, -20);
                cam.transform.rotation = Quaternion.Euler(50, 0, 0);

                // Shop Modal
                menuModals.ShowShop();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_shop_ru.png"));

                // Daily Rewards Modal
                menuModals.ShowDailyRewards();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_daily_rewards_ru.png"));

                // Map Select Modal
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

            // Restore camera
            cam.transform.position = origCamPos;
            cam.transform.rotation = origCamRot;

            Debug.Log("ColorLand: Barcha Phase 9 dizayn tekshiruvi skrinshotlari muvaffaqiyatli olindi!");
        }

        private static void CaptureCamera(Camera cam, string outputPath)
        {
            int width = 1080;
            int height = 1920;

            var rt = new RenderTexture(width, height, 24, RenderTextureFormat.ARGB32);
            var prevRt = cam.targetTexture;
            cam.targetTexture = rt;
            cam.Render();

            RenderTexture.active = rt;
            var tex = new Texture2D(width, height, TextureFormat.RGB24, false);
            tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);
            tex.Apply();

            cam.targetTexture = prevRt;
            RenderTexture.active = null;
            Object.DestroyImmediate(rt);

            byte[] bytes = tex.EncodeToPNG();
            Object.DestroyImmediate(tex);

            File.WriteAllBytes(outputPath, bytes);
        }
    }
}
#endif
