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

            // 1. Sahna yuklash
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

            // A. Shot 1: Asosiy o'yin ekrani to'liq rus tilida (Top Bar, Leaderboard, Joystick)
            Strings.SetLanguage("ru");
            if (GameHUD.Instance != null) GameHUD.Instance.OnLanguageChanged();
            CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_gameplay_ru.png"));
            Debug.Log("[SHOT 1 SAVED] shot_unity_gameplay_ru.png");

            // B. Shot 2: Ochiq Language Picker (15 ta til mahalliy nomlari bilan)
            var langModal = LanguagePickerModal.Instance ?? Object.FindFirstObjectByType<LanguagePickerModal>();
            if (langModal != null)
            {
                langModal.Show();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_language_picker.png"));
                langModal.Hide();
                Debug.Log("[SHOT 2 SAVED] shot_unity_language_picker.png");
            }

            // C. Shot 3: Shahar egallash kartasi (Ixcham, bir-birini yopmaydigan, ruscha "ГОРОД ЗАХВАЧЕН!", "ПОРТ-СУДАН", "+200 🪙")
            var cityNotice = CityNotificationManager.Instance ?? Object.FindFirstObjectByType<CityNotificationManager>();
            if (cityNotice != null && gw != null && gw.CitySystem != null && gw.CitySystem.Cities.Count > 0)
            {
                var city = gw.CitySystem.Cities[0];
                if (cityNotice.CanvasGroup != null)
                {
                    cityNotice.CanvasGroup.alpha = 1.0f;
                }
                if (cityNotice.TitleText != null)
                {
                    cityNotice.TitleText.text = Strings.T("cityCaptured").ToUpperInvariant();
                }
                if (cityNotice.CityNameText != null)
                {
                    cityNotice.CityNameText.text = city.LocalizedName.ToUpperInvariant();
                }
                if (cityNotice.RewardText != null)
                {
                    cityNotice.RewardText.text = $"+{city.RewardCoins} 🪙";
                }
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_city_capture.png"));
                Debug.Log("[SHOT 3 SAVED] shot_unity_city_capture.png");
            }

            // D. Shot 4: Qirg'oq va hudud silliqligi (4x4 izotrop radial kvartik filtr)
            if (gw != null && gw.Player != null)
            {
                gw.CaptureSystem.SpawnInitialTerritory(1, new Vector2Int(gw.GridWidth / 2, gw.GridHeight / 2), 6);
                if (gw.PaintLayer != null) gw.PaintLayer.UpdateFull();
                CaptureCamera(cam, Path.Combine(ArtifactDir, "shot_unity_territory_coastline.png"));
                Debug.Log("[SHOT 4 SAVED] shot_unity_territory_coastline.png");
            }

            Debug.Log("ColorLand: Barcha tekshiruv skrinshotlari muvaffaqiyatli saqlandi!");
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
