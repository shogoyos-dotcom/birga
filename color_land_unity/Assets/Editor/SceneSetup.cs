#if UNITY_EDITOR
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEngine;
using UnityEngine.UI;
using UnityEngine.EventSystems;
using ColorLand.Logic;
using ColorLand.Render;
using ColorLand.UI;

namespace ColorLand.Editor
{
    public static class SceneSetup
    {
        [MenuItem("ColorLand/Build Main Scene")]
        public static void BuildMainScene()
        {
            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // 1. Quyosh (Directional Light)
            var lightObj = new GameObject("Directional Light");
            var light = lightObj.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1.0f, 0.98f, 0.92f);
            lightObj.transform.rotation = Quaternion.Euler(50f, -30f, 0f);

            // 2. Kamera (Main Camera)
            var camObj = new GameObject("Main Camera");
            var cam = camObj.AddComponent<Camera>();
            camObj.tag = "MainCamera";
            camObj.transform.position = new Vector3(0, 35, -25);
            camObj.transform.rotation = Quaternion.Euler(55, 0, 0);

            // 3. Maydon (Arena 120x120)
            var arenaObj = GameObject.CreatePrimitive(PrimitiveType.Plane);
            arenaObj.name = "Arena";
            arenaObj.transform.position = Vector3.zero;
            arenaObj.transform.localScale = new Vector3(12, 1, 12);

            // Arena Material
            var shader = Shader.Find("ColorLand/ArenaShader") ?? Shader.Find("Universal Render Pipeline/Unlit");
            var mat = new Material(shader) { name = "M_Arena" };
            AssetDatabase.CreateAsset(mat, "Assets/Materials/M_Arena.mat");
            arenaObj.GetComponent<Renderer>().sharedMaterial = mat;

            // 4. GameWorld
            var gwObj = new GameObject("GameWorld");
            var gw = gwObj.AddComponent<GameWorld>();
            var paintLayer = arenaObj.AddComponent<PaintLayer>();
            paintLayer.ArenaRenderer = arenaObj.GetComponent<Renderer>();
            paintLayer.ArenaMaterial = mat;
            gw.PaintLayer = paintLayer;
            gw.ArenaMaterial = mat;

            // 5. CityRenderer
            var cityRendererObj = new GameObject("CityRenderer");
            cityRendererObj.transform.SetParent(gwObj.transform);
            var cityRenderer = cityRendererObj.AddComponent<CityRenderer>();
            gw.CityRenderer = cityRenderer;

            // 6. UI Canvas & EventSystem
            BuildUserInterface(gw);

            // Sahnani saqlash
            EditorSceneManager.SaveScene(scene, "Assets/Scenes/MainScene.unity");
            
            // Build Settings ga qo'shish
            EditorBuildSettings.scenes = new[] {
                new EditorBuildSettingsScene("Assets/Scenes/MainScene.unity", true)
            };

            Debug.Log("ColorLand: MainScene.unity to'liq UI va tizimlar bilan muvaffaqiyatli yaratildi!");
        }

        private static void BuildUserInterface(GameWorld gw)
        {
            Font defaultFont = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");
            Sprite uiSprite = Resources.Load<Sprite>("UI/rounded_rect");
            Sprite knobSprite = Resources.Load<Sprite>("UI/knob");

            // EventSystem
            var esObj = new GameObject("EventSystem", typeof(EventSystem), typeof(StandaloneInputModule));

            // Canvas
            var canvasObj = new GameObject("Canvas", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            var canvas = canvasObj.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;

            var scaler = canvasObj.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1080, 1920); // Portrait Android
            scaler.matchWidthOrHeight = 0.5f;

            // GameHUD component
            var hudObj = new GameObject("GameHUD", typeof(RectTransform), typeof(GameHUD));
            hudObj.transform.SetParent(canvasObj.transform, false);
            var hudRt = hudObj.GetComponent<RectTransform>();
            hudRt.anchorMin = Vector2.zero;
            hudRt.anchorMax = Vector2.one;
            hudRt.offsetMin = Vector2.zero;
            hudRt.offsetMax = Vector2.zero;
            var gameHUD = hudObj.GetComponent<GameHUD>();

            // --- A. TOP BAR ---
            var topBarObj = new GameObject("TopBar", typeof(RectTransform), typeof(Image));
            topBarObj.transform.SetParent(hudObj.transform, false);
            var topBarRt = topBarObj.GetComponent<RectTransform>();
            topBarRt.anchorMin = new Vector2(0, 1);
            topBarRt.anchorMax = new Vector2(1, 1);
            topBarRt.pivot = new Vector2(0.5f, 1);
            topBarRt.anchoredPosition = Vector2.zero;
            topBarRt.sizeDelta = new Vector2(0, 100);
            var topBarImg = topBarObj.GetComponent<Image>();
            topBarImg.color = new Color(0.08f, 0.11f, 0.16f, 0.90f);

            // Player Name Text
            var nameObj = CreateText("PlayerName", topBarObj.transform, defaultFont, 24, TextAnchor.MiddleLeft, Color.white);
            var nameRt = nameObj.GetComponent<RectTransform>();
            nameRt.anchorMin = new Vector2(0, 0.5f);
            nameRt.anchorMax = new Vector2(0, 0.5f);
            nameRt.pivot = new Vector2(0, 0.5f);
            nameRt.anchoredPosition = new Vector2(25, 0);
            nameRt.sizeDelta = new Vector2(250, 60);
            gameHUD.PlayerNameText = nameObj.GetComponent<Text>();

            // Territory Percent Text
            var pctObj = CreateText("PercentText", topBarObj.transform, defaultFont, 32, TextAnchor.MiddleCenter, new Color(0.2f, 0.85f, 1.0f));
            var pctRt = pctObj.GetComponent<RectTransform>();
            pctRt.anchorMin = new Vector2(0.45f, 0.5f);
            pctRt.anchorMax = new Vector2(0.45f, 0.5f);
            pctRt.pivot = new Vector2(0.5f, 0.5f);
            pctRt.anchoredPosition = Vector2.zero;
            pctRt.sizeDelta = new Vector2(160, 60);
            gameHUD.TerritoryPercentText = pctObj.GetComponent<Text>();

            // Kills Text
            var killsObj = CreateText("KillsText", topBarObj.transform, defaultFont, 26, TextAnchor.MiddleCenter, new Color(1.0f, 0.4f, 0.4f));
            var killsRt = killsObj.GetComponent<RectTransform>();
            killsRt.anchorMin = new Vector2(0.68f, 0.5f);
            killsRt.anchorMax = new Vector2(0.68f, 0.5f);
            killsRt.pivot = new Vector2(0.5f, 0.5f);
            killsRt.anchoredPosition = Vector2.zero;
            killsRt.sizeDelta = new Vector2(120, 60);
            gameHUD.KillsText = killsObj.GetComponent<Text>();

            // Language Button
            var langBtnObj = new GameObject("LangButton", typeof(RectTransform), typeof(Image), typeof(Button));
            langBtnObj.transform.SetParent(topBarObj.transform, false);
            var langBtnRt = langBtnObj.GetComponent<RectTransform>();
            langBtnRt.anchorMin = new Vector2(1, 0.5f);
            langBtnRt.anchorMax = new Vector2(1, 0.5f);
            langBtnRt.pivot = new Vector2(1, 0.5f);
            langBtnRt.anchoredPosition = new Vector2(-25, 0);
            langBtnRt.sizeDelta = new Vector2(120, 56);
            var langBtnImg = langBtnObj.GetComponent<Image>();
            langBtnImg.sprite = uiSprite;
            langBtnImg.type = Image.Type.Sliced;
            langBtnImg.color = new Color(0.18f, 0.50f, 0.92f);
            gameHUD.LanguageButton = langBtnObj.GetComponent<Button>();

            var langBtnTextObj = CreateText("Label", langBtnObj.transform, defaultFont, 20, TextAnchor.MiddleCenter, Color.white);
            var langBtnTextRt = langBtnTextObj.GetComponent<RectTransform>();
            langBtnTextRt.anchorMin = Vector2.zero;
            langBtnTextRt.anchorMax = Vector2.one;
            langBtnTextRt.offsetMin = Vector2.zero;
            langBtnTextRt.offsetMax = Vector2.zero;
            gameHUD.LanguageButtonText = langBtnTextObj.GetComponent<Text>();

            // --- B. LEADERBOARD ---
            var boardObj = new GameObject("Leaderboard", typeof(RectTransform), typeof(Image));
            boardObj.transform.SetParent(hudObj.transform, false);
            var boardRt = boardObj.GetComponent<RectTransform>();
            boardRt.anchorMin = new Vector2(1, 1);
            boardRt.anchorMax = new Vector2(1, 1);
            boardRt.pivot = new Vector2(1, 1);
            boardRt.anchoredPosition = new Vector2(-20, -120);
            boardRt.sizeDelta = new Vector2(280, 200);
            var boardImg = boardObj.GetComponent<Image>();
            boardImg.sprite = uiSprite;
            boardImg.type = Image.Type.Sliced;
            boardImg.color = new Color(0.08f, 0.11f, 0.16f, 0.85f);

            var boardTitleObj = CreateText("Title", boardObj.transform, defaultFont, 16, TextAnchor.UpperCenter, new Color(1.0f, 0.82f, 0.2f));
            var boardTitleRt = boardTitleObj.GetComponent<RectTransform>();
            boardTitleRt.anchorMin = new Vector2(0, 1);
            boardTitleRt.anchorMax = new Vector2(1, 1);
            boardTitleRt.pivot = new Vector2(0.5f, 1);
            boardTitleRt.anchoredPosition = new Vector2(0, -10);
            boardTitleRt.sizeDelta = new Vector2(0, 30);
            gameHUD.LeaderboardTitleText = boardTitleObj.GetComponent<Text>();

            var boardContentObj = CreateText("Content", boardObj.transform, defaultFont, 16, TextAnchor.UpperLeft, Color.white);
            var boardContentRt = boardContentObj.GetComponent<RectTransform>();
            boardContentRt.anchorMin = Vector2.zero;
            boardContentRt.anchorMax = Vector2.one;
            boardContentRt.offsetMin = new Vector2(15, 10);
            boardContentRt.offsetMax = new Vector2(-15, -40);
            gameHUD.LeaderboardContentText = boardContentObj.GetComponent<Text>();

            // --- C. VIRTUAL JOYSTICK ---
            var joystickObj = new GameObject("VirtualJoystick", typeof(RectTransform));
            joystickObj.transform.SetParent(hudObj.transform, false);
            var joystickRt = joystickObj.GetComponent<RectTransform>();
            joystickRt.anchorMin = new Vector2(0.5f, 0);
            joystickRt.anchorMax = new Vector2(0.5f, 0);
            joystickRt.pivot = new Vector2(0.5f, 0);
            joystickRt.anchoredPosition = new Vector2(0, 80);
            joystickRt.sizeDelta = new Vector2(260, 260);

            var joyBgObj = new GameObject("Background", typeof(RectTransform), typeof(Image));
            joyBgObj.transform.SetParent(joystickObj.transform, false);
            var joyBgRt = joyBgObj.GetComponent<RectTransform>();
            joyBgRt.anchorMin = new Vector2(0.5f, 0.5f);
            joyBgRt.anchorMax = new Vector2(0.5f, 0.5f);
            joyBgRt.sizeDelta = new Vector2(240, 240);
            var joyBgImg = joyBgObj.GetComponent<Image>();
            joyBgImg.sprite = knobSprite ?? uiSprite;
            joyBgImg.color = new Color(1f, 1f, 1f, 0.22f);

            var joyHandleObj = new GameObject("Handle", typeof(RectTransform), typeof(Image));
            joyHandleObj.transform.SetParent(joyBgObj.transform, false);
            var joyHandleRt = joyHandleObj.GetComponent<RectTransform>();
            joyHandleRt.anchorMin = new Vector2(0.5f, 0.5f);
            joyHandleRt.anchorMax = new Vector2(0.5f, 0.5f);
            joyHandleRt.sizeDelta = new Vector2(90, 90);
            var joyHandleImg = joyHandleObj.GetComponent<Image>();
            joyHandleImg.sprite = knobSprite ?? uiSprite;
            joyHandleImg.color = new Color(1f, 1f, 1f, 0.75f);

            var joystickComp = joystickObj.AddComponent<VirtualJoystick>();
            joystickComp.Background = joyBgRt;
            joystickComp.Handle = joyHandleRt;
            joystickComp.HandleRange = 80f;

            // --- D. CITY NOTIFICATION CARD (TASK 5) ---
            var noticeCardObj = new GameObject("CityNotificationCard", typeof(RectTransform), typeof(Image), typeof(CanvasGroup), typeof(CityNotificationManager));
            noticeCardObj.transform.SetParent(hudObj.transform, false);
            var noticeCardRt = noticeCardObj.GetComponent<RectTransform>();
            noticeCardRt.anchorMin = new Vector2(0.5f, 1);
            noticeCardRt.anchorMax = new Vector2(0.5f, 1);
            noticeCardRt.pivot = new Vector2(0.5f, 1);
            noticeCardRt.anchoredPosition = new Vector2(0, -130);
            noticeCardRt.sizeDelta = new Vector2(460, 140);

            var noticeImg = noticeCardObj.GetComponent<Image>();
            noticeImg.sprite = uiSprite;
            noticeImg.type = Image.Type.Sliced;
            noticeImg.color = new Color(0.09f, 0.13f, 0.20f, 0.95f);

            var noticeMgr = noticeCardObj.GetComponent<CityNotificationManager>();
            noticeMgr.NotificationPanel = noticeCardRt;
            noticeMgr.CanvasGroup = noticeCardObj.GetComponent<CanvasGroup>();

            // Title: "ГОРОД ЗАХВАЧЕН!"
            var cTitleObj = CreateText("NoticeTitle", noticeCardObj.transform, defaultFont, 18, TextAnchor.MiddleCenter, new Color(1.0f, 0.85f, 0.2f));
            var cTitleRt = cTitleObj.GetComponent<RectTransform>();
            cTitleRt.anchorMin = new Vector2(0, 1);
            cTitleRt.anchorMax = new Vector2(1, 1);
            cTitleRt.pivot = new Vector2(0.5f, 1);
            cTitleRt.anchoredPosition = new Vector2(0, -10);
            cTitleRt.sizeDelta = new Vector2(0, 30);
            noticeMgr.TitleText = cTitleObj.GetComponent<Text>();

            // City Name: "ПОРТ-СУДАН"
            var cNameObj = CreateText("CityName", noticeCardObj.transform, defaultFont, 28, TextAnchor.MiddleCenter, Color.white);
            var cNameRt = cNameObj.GetComponent<RectTransform>();
            cNameRt.anchorMin = new Vector2(0, 0.5f);
            cNameRt.anchorMax = new Vector2(1, 0.5f);
            cNameRt.pivot = new Vector2(0.5f, 0.5f);
            cNameRt.anchoredPosition = new Vector2(0, 5);
            cNameRt.sizeDelta = new Vector2(0, 40);
            noticeMgr.CityNameText = cNameObj.GetComponent<Text>();

            // Reward: "+200 🪙"
            var cRewardObj = CreateText("Reward", noticeCardObj.transform, defaultFont, 22, TextAnchor.MiddleCenter, new Color(0.99f, 0.90f, 0.35f));
            var cRewardRt = cRewardObj.GetComponent<RectTransform>();
            cRewardRt.anchorMin = new Vector2(0, 0);
            cRewardRt.anchorMax = new Vector2(1, 0);
            cRewardRt.pivot = new Vector2(0.5f, 0);
            cRewardRt.anchoredPosition = new Vector2(0, 12);
            cRewardRt.sizeDelta = new Vector2(0, 32);
            noticeMgr.RewardText = cRewardObj.GetComponent<Text>();

            // --- E. LANGUAGE PICKER MODAL (TASK 2) ---
            var modalRootObj = new GameObject("LanguagePickerModal", typeof(RectTransform), typeof(Image), typeof(LanguagePickerModal));
            modalRootObj.transform.SetParent(hudObj.transform, false);
            var modalRootRt = modalRootObj.GetComponent<RectTransform>();
            modalRootRt.anchorMin = Vector2.zero;
            modalRootRt.anchorMax = Vector2.one;
            modalRootRt.offsetMin = Vector2.zero;
            modalRootRt.offsetMax = Vector2.zero;
            var modalDimImg = modalRootObj.GetComponent<Image>();
            modalDimImg.color = new Color(0f, 0f, 0f, 0.70f);

            var modal = modalRootObj.GetComponent<LanguagePickerModal>();
            modal.ModalRoot = modalRootObj;

            // Dialog Window
            var dialogObj = new GameObject("DialogWindow", typeof(RectTransform), typeof(Image));
            dialogObj.transform.SetParent(modalRootObj.transform, false);
            var dialogRt = dialogObj.GetComponent<RectTransform>();
            dialogRt.anchorMin = new Vector2(0.5f, 0.5f);
            dialogRt.anchorMax = new Vector2(0.5f, 0.5f);
            dialogRt.sizeDelta = new Vector2(560, 800);
            var dialogImg = dialogObj.GetComponent<Image>();
            dialogImg.sprite = uiSprite;
            dialogImg.type = Image.Type.Sliced;
            dialogImg.color = new Color(0.11f, 0.15f, 0.22f, 0.98f);

            // Dialog Header Title
            var dlgHeaderObj = CreateText("Title", dialogObj.transform, defaultFont, 26, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            var dlgHeaderRt = dlgHeaderObj.GetComponent<RectTransform>();
            dlgHeaderRt.anchorMin = new Vector2(0, 1);
            dlgHeaderRt.anchorMax = new Vector2(1, 1);
            dlgHeaderRt.pivot = new Vector2(0.5f, 1);
            dlgHeaderRt.anchoredPosition = new Vector2(0, -18);
            dlgHeaderRt.sizeDelta = new Vector2(0, 45);
            modal.HeaderTitle = dlgHeaderObj.GetComponent<Text>();

            // Close Button
            var closeBtnObj = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
            closeBtnObj.transform.SetParent(dialogObj.transform, false);
            var closeBtnRt = closeBtnObj.GetComponent<RectTransform>();
            closeBtnRt.anchorMin = new Vector2(1, 1);
            closeBtnRt.anchorMax = new Vector2(1, 1);
            closeBtnRt.pivot = new Vector2(1, 1);
            closeBtnRt.anchoredPosition = new Vector2(-15, -15);
            closeBtnRt.sizeDelta = new Vector2(50, 50);
            var closeBtnImg = closeBtnObj.GetComponent<Image>();
            closeBtnImg.sprite = uiSprite;
            closeBtnImg.type = Image.Type.Sliced;
            closeBtnImg.color = new Color(0.75f, 0.20f, 0.20f);
            modal.CloseButton = closeBtnObj.GetComponent<Button>();

            var closeLblObj = CreateText("X", closeBtnObj.transform, defaultFont, 24, TextAnchor.MiddleCenter, Color.white);
            var closeLblRt = closeLblObj.GetComponent<RectTransform>();
            closeLblRt.anchorMin = Vector2.zero;
            closeLblRt.anchorMax = Vector2.one;
            closeLblRt.offsetMin = Vector2.zero;
            closeLblRt.offsetMax = Vector2.zero;

            // ScrollView for Languages
            var scrollObj = new GameObject("ScrollView", typeof(RectTransform), typeof(ScrollRect), typeof(Image));
            scrollObj.transform.SetParent(dialogObj.transform, false);
            var scrollRt = scrollObj.GetComponent<RectTransform>();
            scrollRt.anchorMin = Vector2.zero;
            scrollRt.anchorMax = Vector2.one;
            scrollRt.offsetMin = new Vector2(20, 20);
            scrollRt.offsetMax = new Vector2(-20, -75);
            var scrollImg = scrollObj.GetComponent<Image>();
            scrollImg.color = new Color(0.06f, 0.08f, 0.12f, 0.6f);

            var scroll = scrollObj.GetComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;

            var viewportObj = new GameObject("Viewport", typeof(RectTransform), typeof(Mask), typeof(Image));
            viewportObj.transform.SetParent(scrollObj.transform, false);
            var viewportRt = viewportObj.GetComponent<RectTransform>();
            viewportRt.anchorMin = Vector2.zero;
            viewportRt.anchorMax = Vector2.one;
            viewportRt.offsetMin = Vector2.zero;
            viewportRt.offsetMax = Vector2.zero;
            var vpMask = viewportObj.GetComponent<Mask>();
            vpMask.showMaskGraphic = false;

            var contentObj = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            contentObj.transform.SetParent(viewportObj.transform, false);
            var contentRt = contentObj.GetComponent<RectTransform>();
            contentRt.anchorMin = new Vector2(0, 1);
            contentRt.anchorMax = new Vector2(1, 1);
            contentRt.pivot = new Vector2(0.5f, 1);
            contentRt.sizeDelta = new Vector2(0, 0);

            var vlg = contentObj.GetComponent<VerticalLayoutGroup>();
            vlg.spacing = 8;
            vlg.padding = new RectOffset(8, 8, 8, 8);
            vlg.childForceExpandWidth = true;
            vlg.childForceExpandHeight = false;
            vlg.childControlWidth = true;
            vlg.childControlHeight = false;

            var csf = contentObj.GetComponent<ContentSizeFitter>();
            csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            scroll.viewport = viewportRt;
            scroll.content = contentRt;
            modal.ContentContainer = contentRt;

            // --- F. GAME OVER PANEL ---
            var overObj = new GameObject("GameOverPanel", typeof(RectTransform), typeof(Image));
            overObj.transform.SetParent(hudObj.transform, false);
            var overRt = overObj.GetComponent<RectTransform>();
            overRt.anchorMin = Vector2.zero;
            overRt.anchorMax = Vector2.one;
            overRt.offsetMin = Vector2.zero;
            overRt.offsetMax = Vector2.zero;
            var overImg = overObj.GetComponent<Image>();
            overImg.color = new Color(0f, 0f, 0f, 0.85f);
            gameHUD.GameOverPanel = overObj;

            var overTitleObj = CreateText("Title", overObj.transform, defaultFont, 40, TextAnchor.MiddleCenter, new Color(1.0f, 0.35f, 0.35f));
            var overTitleRt = overTitleObj.GetComponent<RectTransform>();
            overTitleRt.anchorMin = new Vector2(0.5f, 0.65f);
            overTitleRt.anchorMax = new Vector2(0.5f, 0.65f);
            overTitleRt.sizeDelta = new Vector2(500, 60);
            gameHUD.GameOverTitleText = overTitleObj.GetComponent<Text>();

            var overStatsObj = CreateText("Stats", overObj.transform, defaultFont, 24, TextAnchor.MiddleCenter, Color.white);
            var overStatsRt = overStatsObj.GetComponent<RectTransform>();
            overStatsRt.anchorMin = new Vector2(0.5f, 0.52f);
            overStatsRt.anchorMax = new Vector2(0.5f, 0.52f);
            overStatsRt.sizeDelta = new Vector2(400, 100);
            gameHUD.GameOverStatsText = overStatsObj.GetComponent<Text>();

            var playAgainBtnObj = new GameObject("PlayAgainBtn", typeof(RectTransform), typeof(Image), typeof(Button));
            playAgainBtnObj.transform.SetParent(overObj.transform, false);
            var playAgainBtnRt = playAgainBtnObj.GetComponent<RectTransform>();
            playAgainBtnRt.anchorMin = new Vector2(0.5f, 0.38f);
            playAgainBtnRt.anchorMax = new Vector2(0.5f, 0.38f);
            playAgainBtnRt.sizeDelta = new Vector2(280, 70);
            var playAgainImg = playAgainBtnObj.GetComponent<Image>();
            playAgainImg.sprite = uiSprite;
            playAgainImg.type = Image.Type.Sliced;
            playAgainImg.color = new Color(0.18f, 0.72f, 0.38f);
            gameHUD.PlayAgainButton = playAgainBtnObj.GetComponent<Button>();

            var playAgainLblObj = CreateText("Label", playAgainBtnObj.transform, defaultFont, 24, TextAnchor.MiddleCenter, Color.white);
            var playAgainLblRt = playAgainLblObj.GetComponent<RectTransform>();
            playAgainLblRt.anchorMin = Vector2.zero;
            playAgainLblRt.anchorMax = Vector2.one;
            playAgainLblRt.offsetMin = Vector2.zero;
            playAgainLblRt.offsetMax = Vector2.zero;
            gameHUD.PlayAgainButtonText = playAgainLblObj.GetComponent<Text>();

            overObj.SetActive(false);
        }

        private static GameObject CreateText(string name, Transform parent, Font font, int size, TextAnchor align, Color color)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Text));
            go.transform.SetParent(parent, false);
            var txt = go.GetComponent<Text>();
            txt.font = font;
            txt.fontSize = size;
            txt.alignment = align;
            txt.color = color;
            txt.supportRichText = true;
            txt.raycastTarget = false;
            return go;
        }
    }
}
#endif
