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
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
            EnsureAlwaysIncludedShaders();

            var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);

            // 1. Quyosh (Directional Light) va Muhit yorug'ligi
            var lightObj = new GameObject("Directional Light");
            var light = lightObj.AddComponent<Light>();
            light.type = LightType.Directional;
            light.color = new Color(1.0f, 0.96f, 0.88f);
            light.intensity = 1.10f;
            light.shadows = LightShadows.Soft;
            light.shadowStrength = 0.65f;
            lightObj.transform.rotation = Quaternion.Euler(48f, -32f, 0f);

            RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Trilight;
            RenderSettings.ambientSkyColor = new Color(0.48f, 0.68f, 0.88f);
            RenderSettings.ambientEquatorColor = new Color(0.38f, 0.58f, 0.32f);
            RenderSettings.ambientGroundColor = new Color(0.18f, 0.30f, 0.14f);

            // 2. Kamera (Main Camera)
            var camObj = new GameObject("Main Camera");
            var cam = camObj.AddComponent<Camera>();
            camObj.tag = "MainCamera";
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(0.04f, 0.50f, 0.82f);
            camObj.transform.position = new Vector3(0, 24, -18);
            camObj.transform.rotation = Quaternion.Euler(52, 0, 0);

            // Papkalarni ta'minlash
            if (!System.IO.Directory.Exists("Assets/Materials")) System.IO.Directory.CreateDirectory("Assets/Materials");
            if (!System.IO.Directory.Exists("Assets/Resources/Materials")) System.IO.Directory.CreateDirectory("Assets/Resources/Materials");

            // 3. Okean suvi (400x400 ulkan tropik suv qatlami)
            var oceanObj = GameObject.CreatePrimitive(PrimitiveType.Plane);
            oceanObj.name = "Ocean";
            oceanObj.transform.position = new Vector3(0, -0.08f, 0);
            oceanObj.transform.localScale = new Vector3(40, 1, 40);
            var oceanCol = oceanObj.GetComponent<Collider>();
            if (oceanCol != null) Object.DestroyImmediate(oceanCol);

            var waterShader = Shader.Find("ColorLand/WaterShader") ?? Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Mobile/Diffuse");
            var waterMat = new Material(waterShader) { name = "M_Water" };
            AssetDatabase.CreateAsset(waterMat, "Assets/Materials/M_Water.mat");
            oceanObj.GetComponent<Renderer>().sharedMaterial = waterMat;

            // 4. Maydon (Arena 120x120)
            var arenaObj = GameObject.CreatePrimitive(PrimitiveType.Plane);
            arenaObj.name = "Arena";
            arenaObj.transform.position = Vector3.zero;
            arenaObj.transform.localScale = new Vector3(12, 1, 12);

            var arenaShader = Shader.Find("ColorLand/ArenaShader") ?? Shader.Find("Universal Render Pipeline/Unlit") ?? Shader.Find("Mobile/Diffuse");
            var arenaMat = new Material(arenaShader) { name = "M_Arena" };
            AssetDatabase.CreateAsset(arenaMat, "Assets/Materials/M_Arena.mat");
            arenaObj.GetComponent<Renderer>().sharedMaterial = arenaMat;

            // 5. Atrof-muhit bezaklari (Multfilm daraxtlari va qoyalari)
            CreateDecorativeEnvironment();

            // 6. GameWorld
            var gwObj = new GameObject("GameWorld");
            var gw = gwObj.AddComponent<GameWorld>();
            var paintLayer = arenaObj.AddComponent<PaintLayer>();
            paintLayer.ArenaRenderer = arenaObj.GetComponent<Renderer>();
            paintLayer.ArenaMaterial = arenaMat;
            gw.PaintLayer = paintLayer;
            gw.ArenaMaterial = arenaMat;

            // 7. CityRenderer
            var cityRendererObj = new GameObject("CityRenderer");
            cityRendererObj.transform.SetParent(gwObj.transform);
            var cityRenderer = cityRendererObj.AddComponent<CityRenderer>();
            gw.CityRenderer = cityRenderer;

            // 8. UI Canvas & EventSystem
            BuildUserInterface(gw);

            // Sahnani saqlash
            EditorSceneManager.SaveScene(scene, "Assets/Scenes/MainScene.unity");
            
            // Build Settings ga qo'shish
            EditorBuildSettings.scenes = new[] {
                new EditorBuildSettingsScene("Assets/Scenes/MainScene.unity", true)
            };

            Debug.Log("ColorLand: MainScene.unity to'liq 3D multfilm muhiti, suv, arena va UI bilan muvaffaqiyatli yaratildi!");
        }

        private static void CreateDecorativeEnvironment()
        {
            var envRoot = new GameObject("Environment");
            // Boyitilgan tabiat manzarasi (Blender FBX: Qorli tog'lar, yog'och ko'priklar, qoyalar, archa va dumaloq daraxtlar)
            ColorLand.Render.EnvironmentBuilder.BuildRichEnvironment(envRoot);
        }

        private static void EnsureAlwaysIncludedShaders()
        {
            string[] shaderNames = new string[]
            {
                "ColorLand/ArenaShader",
                "ColorLand/WaterShader",
                "ColorLand/CartoonLit",
                "ColorLand/TrailShader",
                "Universal Render Pipeline/Lit",
                "Universal Render Pipeline/Unlit",
                "Standard",
                "Sprites/Default",
                "Mobile/Diffuse",
                "Mobile/Unlit"
            };

            var graphicsSettingsAsset = AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/GraphicsSettings.asset");
            if (graphicsSettingsAsset != null && graphicsSettingsAsset.Length > 0)
            {
                SerializedObject graphicsSettings = new SerializedObject(graphicsSettingsAsset[0]);
                SerializedProperty prop = graphicsSettings.FindProperty("m_AlwaysIncludedShaders");
                if (prop != null)
                {
                    bool modified = false;
                    foreach (var sName in shaderNames)
                    {
                        var s = Shader.Find(sName);
                        if (s == null) continue;

                        bool found = false;
                        for (int i = 0; i < prop.arraySize; i++)
                        {
                            var elem = prop.GetArrayElementAtIndex(i);
                            if (elem.objectReferenceValue == s)
                            {
                                found = true;
                                break;
                            }
                        }

                        if (!found)
                        {
                            int newIdx = prop.arraySize;
                            prop.InsertArrayElementAtIndex(newIdx);
                            prop.GetArrayElementAtIndex(newIdx).objectReferenceValue = s;
                            modified = true;
                        }
                    }

                    if (modified)
                    {
                        graphicsSettings.ApplyModifiedProperties();
                        AssetDatabase.SaveAssets();
                        Debug.Log("ColorLand: m_AlwaysIncludedShaders muvaffaqiyatli yangilandi!");
                    }
                }
            }
        }

        private static void BuildUserInterface(GameWorld gw)
        {
            Font defaultFont = Resources.Load<Font>("Fonts/Fredoka") 
                            ?? Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") 
                            ?? Resources.GetBuiltinResource<Font>("Arial.ttf");

            Sprite uiSprite = Resources.Load<Sprite>("UI/rounded_rect");
            Sprite btnGreen = Resources.Load<Sprite>("UI/btn_green") ?? uiSprite;
            Sprite btnBlue = Resources.Load<Sprite>("UI/btn_blue") ?? uiSprite;
            Sprite btnOrange = Resources.Load<Sprite>("UI/btn_orange") ?? uiSprite;
            Sprite btnPurple = Resources.Load<Sprite>("UI/btn_purple") ?? uiSprite;
            Sprite btnSlate = Resources.Load<Sprite>("UI/btn_slate") ?? uiSprite;
            Sprite pillCyan = Resources.Load<Sprite>("UI/pill_cyan") ?? uiSprite;
            Sprite pillNavy = Resources.Load<Sprite>("UI/pill_navy") ?? uiSprite;
            Sprite panelDialog = Resources.Load<Sprite>("UI/panel_dialog") ?? uiSprite;
            Sprite panelBoard = Resources.Load<Sprite>("UI/panel_leaderboard") ?? uiSprite;
            Sprite joyRing = Resources.Load<Sprite>("UI/joy_ring") ?? Resources.Load<Sprite>("UI/knob");
            Sprite joyKnob = Resources.Load<Sprite>("UI/joy_knob") ?? Resources.Load<Sprite>("UI/knob");
            Sprite badgeExcl = Resources.Load<Sprite>("UI/badge_exclamation");

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

            // Gameplay HUD Group (TopBar, Leaderboard, Joystick - Menyuda yashiriladi)
            var gameplayGroup = new GameObject("GameplayHUDGroup", typeof(RectTransform));
            gameplayGroup.transform.SetParent(hudObj.transform, false);
            var ggRt = gameplayGroup.GetComponent<RectTransform>();
            ggRt.anchorMin = Vector2.zero;
            ggRt.anchorMax = Vector2.one;
            ggRt.offsetMin = Vector2.zero;
            ggRt.offsetMax = Vector2.zero;
            gameHUD.GameplayHUDGroup = gameplayGroup;

            // --- A. TOP FLOATING PILLS (Header) ---
            var topBarObj = new GameObject("TopBar", typeof(RectTransform));
            topBarObj.transform.SetParent(gameplayGroup.transform, false);
            var topBarRt = topBarObj.GetComponent<RectTransform>();
            topBarRt.anchorMin = new Vector2(0, 1);
            topBarRt.anchorMax = new Vector2(1, 1);
            topBarRt.pivot = new Vector2(0.5f, 1);
            topBarRt.anchoredPosition = Vector2.zero;
            topBarRt.sizeDelta = new Vector2(0, 110);

            // 1. Menu Button Pill [ ☰ МЕНЮ ]
            var menuBtnObj = new GameObject("MenuButton", typeof(RectTransform), typeof(Image), typeof(Button));
            menuBtnObj.transform.SetParent(topBarObj.transform, false);
            var menuBtnRt = menuBtnObj.GetComponent<RectTransform>();
            menuBtnRt.anchorMin = new Vector2(0, 1);
            menuBtnRt.anchorMax = new Vector2(0, 1);
            menuBtnRt.pivot = new Vector2(0, 1);
            menuBtnRt.anchoredPosition = new Vector2(25, -25);
            menuBtnRt.sizeDelta = new Vector2(165, 58);
            var menuBtnImg = menuBtnObj.GetComponent<Image>();
            menuBtnImg.sprite = pillNavy;
            menuBtnImg.type = Image.Type.Sliced;
            menuBtnImg.color = Color.white;
            gameHUD.MenuButton = menuBtnObj.GetComponent<Button>();

            var menuBtnTextObj = CreateText("Label", menuBtnObj.transform, defaultFont, 22, TextAnchor.MiddleCenter, Color.white);
            var menuBtnTextRt = menuBtnTextObj.GetComponent<RectTransform>();
            menuBtnTextRt.anchorMin = Vector2.zero;
            menuBtnTextRt.anchorMax = Vector2.one;
            menuBtnTextRt.offsetMin = Vector2.zero;
            menuBtnTextRt.offsetMax = Vector2.zero;
            var mbTxt = menuBtnTextObj.GetComponent<Text>();
            mbTxt.fontStyle = FontStyle.Bold;
            mbTxt.text = "☰ МЕНЮ";
            gameHUD.MenuButtonText = mbTxt;

            // 2. Territory Percent Pill (Glowing Cyan Capsule) (● 12,5%)
            var pctPillObj = new GameObject("PercentPill", typeof(RectTransform), typeof(Image));
            pctPillObj.transform.SetParent(topBarObj.transform, false);
            var pctPillRt = pctPillObj.GetComponent<RectTransform>();
            pctPillRt.anchorMin = new Vector2(0, 1);
            pctPillRt.anchorMax = new Vector2(0, 1);
            pctPillRt.pivot = new Vector2(0, 1);
            pctPillRt.anchoredPosition = new Vector2(200, -25);
            pctPillRt.sizeDelta = new Vector2(165, 58);
            var pctPillImg = pctPillObj.GetComponent<Image>();
            pctPillImg.sprite = pillCyan;
            pctPillImg.type = Image.Type.Sliced;
            pctPillImg.color = Color.white;

            var pctObj = CreateText("PercentText", pctPillObj.transform, defaultFont, 24, TextAnchor.MiddleCenter, Color.white);
            var pctRt = pctObj.GetComponent<RectTransform>();
            pctRt.anchorMin = Vector2.zero;
            pctRt.anchorMax = Vector2.one;
            pctRt.offsetMin = Vector2.zero;
            pctRt.offsetMax = Vector2.zero;
            var pctTxt = pctObj.GetComponent<Text>();
            pctTxt.fontStyle = FontStyle.Bold;
            pctTxt.text = "● 12.5%";
            gameHUD.TerritoryPercentText = pctTxt;

            // 3. Crown Pill [ 👑 3 ]
            var crownPillObj = new GameObject("CrownPill", typeof(RectTransform), typeof(Image));
            crownPillObj.transform.SetParent(topBarObj.transform, false);
            var crownPillRt = crownPillObj.GetComponent<RectTransform>();
            crownPillRt.anchorMin = new Vector2(1, 1);
            crownPillRt.anchorMax = new Vector2(1, 1);
            crownPillRt.pivot = new Vector2(1, 1);
            crownPillRt.anchoredPosition = new Vector2(-195, -25);
            crownPillRt.sizeDelta = new Vector2(135, 58);
            var crownPillImg = crownPillObj.GetComponent<Image>();
            crownPillImg.sprite = pillNavy;
            crownPillImg.type = Image.Type.Sliced;
            crownPillImg.color = Color.white;

            var killsObj = CreateText("KillsText", crownPillObj.transform, defaultFont, 24, TextAnchor.MiddleCenter, Color.white);
            var killsRt = killsObj.GetComponent<RectTransform>();
            killsRt.anchorMin = Vector2.zero;
            killsRt.anchorMax = Vector2.one;
            killsRt.offsetMin = Vector2.zero;
            killsRt.offsetMax = Vector2.zero;
            var killsTxt = killsObj.GetComponent<Text>();
            killsTxt.fontStyle = FontStyle.Bold;
            killsTxt.text = "👑 3";
            gameHUD.KillsText = killsTxt;

            // 4. Language Button Pill [ 🇷🇺 RU ]
            var langBtnObj = new GameObject("LangButton", typeof(RectTransform), typeof(Image), typeof(Button));
            langBtnObj.transform.SetParent(topBarObj.transform, false);
            var langBtnRt = langBtnObj.GetComponent<RectTransform>();
            langBtnRt.anchorMin = new Vector2(1, 1);
            langBtnRt.anchorMax = new Vector2(1, 1);
            langBtnRt.pivot = new Vector2(1, 1);
            langBtnRt.anchoredPosition = new Vector2(-25, -25);
            langBtnRt.sizeDelta = new Vector2(155, 58);
            var langBtnImg = langBtnObj.GetComponent<Image>();
            langBtnImg.sprite = pillNavy;
            langBtnImg.type = Image.Type.Sliced;
            langBtnImg.color = Color.white;
            gameHUD.LanguageButton = langBtnObj.GetComponent<Button>();

            var langBtnTextObj = CreateText("Label", langBtnObj.transform, defaultFont, 22, TextAnchor.MiddleCenter, Color.white);
            var langBtnTextRt = langBtnTextObj.GetComponent<RectTransform>();
            langBtnTextRt.anchorMin = Vector2.zero;
            langBtnTextRt.anchorMax = Vector2.one;
            langBtnTextRt.offsetMin = Vector2.zero;
            langBtnTextRt.offsetMax = Vector2.zero;
            var lbTxt = langBtnTextObj.GetComponent<Text>();
            lbTxt.fontStyle = FontStyle.Bold;
            lbTxt.text = "🇷🇺 RU";
            gameHUD.LanguageButtonText = lbTxt;

            // --- B. LEADERBOARD (РЕЙТИНГ) ---
            var boardObj = new GameObject("Leaderboard", typeof(RectTransform), typeof(Image));
            boardObj.transform.SetParent(gameplayGroup.transform, false);
            var boardRt = boardObj.GetComponent<RectTransform>();
            boardRt.anchorMin = new Vector2(1, 1);
            boardRt.anchorMax = new Vector2(1, 1);
            boardRt.pivot = new Vector2(1, 1);
            boardRt.anchoredPosition = new Vector2(-25, -100);
            boardRt.sizeDelta = new Vector2(310, 240);
            var boardImg = boardObj.GetComponent<Image>();
            boardImg.sprite = panelBoard;
            boardImg.type = Image.Type.Sliced;
            boardImg.color = Color.white;

            var boardTitleObj = CreateText("Title", boardObj.transform, defaultFont, 20, TextAnchor.UpperCenter, new Color(0.98f, 0.80f, 0.08f));
            var boardTitleRt = boardTitleObj.GetComponent<RectTransform>();
            boardTitleRt.anchorMin = new Vector2(0, 1);
            boardTitleRt.anchorMax = new Vector2(1, 1);
            boardTitleRt.pivot = new Vector2(0.5f, 1);
            boardTitleRt.anchoredPosition = new Vector2(0, -12);
            boardTitleRt.sizeDelta = new Vector2(0, 30);
            var btComp = boardTitleObj.GetComponent<Text>();
            btComp.fontStyle = FontStyle.Bold;
            btComp.text = "РЕЙТИНГ";
            gameHUD.LeaderboardTitleText = btComp;

            var boardContentObj = CreateText("Content", boardObj.transform, defaultFont, 17, TextAnchor.UpperLeft, Color.white);
            var boardContentRt = boardContentObj.GetComponent<RectTransform>();
            boardContentRt.anchorMin = Vector2.zero;
            boardContentRt.anchorMax = Vector2.one;
            boardContentRt.offsetMin = new Vector2(16, 10);
            boardContentRt.offsetMax = new Vector2(-16, -45);
            var bcTxt = boardContentObj.GetComponent<Text>();
            bcTxt.lineSpacing = 1.15f;
            bcTxt.text =
                "<b><color=#38bdf8>1. [UZ] SHO       12,5%</color></b>\n" +
                "<color=#f1f5f9>2. Berlin [DE]      8,1%</color>\n" +
                "<color=#f1f5f9>3. Samarkand [UZ]   6,7%</color>\n" +
                "<color=#f1f5f9>4. Dubai [AE]       5,2%</color>\n" +
                "<color=#f1f5f9>5. Cairo [EG]       4,1%</color>";
            gameHUD.LeaderboardContentText = bcTxt;

            // --- C. VIRTUAL JOYSTICK ---
            var joystickObj = new GameObject("VirtualJoystick", typeof(RectTransform));
            joystickObj.transform.SetParent(gameplayGroup.transform, false);
            var joystickRt = joystickObj.GetComponent<RectTransform>();
            joystickRt.anchorMin = new Vector2(0.5f, 0);
            joystickRt.anchorMax = new Vector2(0.5f, 0);
            joystickRt.pivot = new Vector2(0.5f, 0);
            joystickRt.anchoredPosition = new Vector2(0, 85);
            joystickRt.sizeDelta = new Vector2(260, 260);

            var joyBgObj = new GameObject("Background", typeof(RectTransform), typeof(Image));
            joyBgObj.transform.SetParent(joystickObj.transform, false);
            var joyBgRt = joyBgObj.GetComponent<RectTransform>();
            joyBgRt.anchorMin = new Vector2(0.5f, 0.5f);
            joyBgRt.anchorMax = new Vector2(0.5f, 0.5f);
            joyBgRt.sizeDelta = new Vector2(240, 240);
            var joyBgImg = joyBgObj.GetComponent<Image>();
            joyBgImg.sprite = joyRing;
            joyBgImg.color = Color.white;

            var joyHandleObj = new GameObject("Handle", typeof(RectTransform), typeof(Image));
            joyHandleObj.transform.SetParent(joyBgObj.transform, false);
            var joyHandleRt = joyHandleObj.GetComponent<RectTransform>();
            joyHandleRt.anchorMin = new Vector2(0.5f, 0.5f);
            joyHandleRt.anchorMax = new Vector2(0.5f, 0.5f);
            joyHandleRt.sizeDelta = new Vector2(100, 100);
            var joyHandleImg = joyHandleObj.GetComponent<Image>();
            joyHandleImg.sprite = joyKnob;
            joyHandleImg.color = Color.white;

            var joystickComp = joystickObj.AddComponent<VirtualJoystick>();
            joystickComp.Background = joyBgRt;
            joystickComp.Handle = joyHandleRt;
            joystickComp.HandleRange = 80f;

            // --- D. CITY NOTIFICATION CARD (TASK 5) ---
            var noticeCardObj = new GameObject("CityNotificationCard", typeof(RectTransform), typeof(Image), typeof(CanvasGroup), typeof(CityNotificationManager));
            noticeCardObj.transform.SetParent(gameplayGroup.transform, false);
            var noticeCardRt = noticeCardObj.GetComponent<RectTransform>();
            noticeCardRt.anchorMin = new Vector2(0.5f, 1);
            noticeCardRt.anchorMax = new Vector2(0.5f, 1);
            noticeCardRt.pivot = new Vector2(0.5f, 1);
            noticeCardRt.anchoredPosition = new Vector2(0, -130);
            noticeCardRt.sizeDelta = new Vector2(460, 140);

            var noticeImg = noticeCardObj.GetComponent<Image>();
            noticeImg.sprite = panelDialog;
            noticeImg.type = Image.Type.Sliced;
            noticeImg.color = Color.white;

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

            var dialogObj = new GameObject("DialogWindow", typeof(RectTransform), typeof(Image));
            dialogObj.transform.SetParent(modalRootObj.transform, false);
            var dialogRt = dialogObj.GetComponent<RectTransform>();
            dialogRt.anchorMin = new Vector2(0.5f, 0.5f);
            dialogRt.anchorMax = new Vector2(0.5f, 0.5f);
            dialogRt.sizeDelta = new Vector2(560, 800);
            var dialogImg = dialogObj.GetComponent<Image>();
            dialogImg.sprite = panelDialog;
            dialogImg.type = Image.Type.Sliced;
            dialogImg.color = Color.white;

            var dlgHeaderObj = CreateText("Title", dialogObj.transform, defaultFont, 26, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            var dlgHeaderRt = dlgHeaderObj.GetComponent<RectTransform>();
            dlgHeaderRt.anchorMin = new Vector2(0, 1);
            dlgHeaderRt.anchorMax = new Vector2(1, 1);
            dlgHeaderRt.pivot = new Vector2(0.5f, 1);
            dlgHeaderRt.anchoredPosition = new Vector2(0, -18);
            dlgHeaderRt.sizeDelta = new Vector2(0, 45);
            modal.HeaderTitle = dlgHeaderObj.GetComponent<Text>();

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

            // --- F. MENU MODALS (Shop, Daily Rewards, Maps, Main Menu) ---
            BuildNavigationModals(hudObj, defaultFont, panelDialog, btnGreen, btnBlue, btnOrange, btnPurple, btnSlate, badgeExcl, pillNavy);

            // --- G. GAME OVER PANEL ---
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
            playAgainImg.sprite = btnGreen;
            playAgainImg.type = Image.Type.Sliced;
            playAgainImg.color = Color.white;
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

        private static void BuildNavigationModals(GameObject hudObj, Font font, Sprite panelDialog, Sprite btnGreen, Sprite btnBlue, Sprite btnOrange, Sprite btnPurple, Sprite btnSlate, Sprite badgeExcl, Sprite pillNavy)
        {
            var menuModals = hudObj.AddComponent<MenuModals>();

            // 1. Main Menu Screen (Full-Screen Clean Layout matching reference image media_1792869223526_a5380204.jpg)
            var menuModalObj = new GameObject("MainMenuModal", typeof(RectTransform));
            menuModalObj.transform.SetParent(hudObj.transform, false);
            var menuRt = menuModalObj.GetComponent<RectTransform>();
            menuRt.anchorMin = Vector2.zero;
            menuRt.anchorMax = Vector2.one;
            menuRt.offsetMin = Vector2.zero;
            menuRt.offsetMax = Vector2.zero;
            menuModals.MainMenuPanel = menuModalObj;

            // 1. 3D Bubble Extruded Title Logo "COLOR LAND 3D" (Matching reference media_1792869223526_a5380204.jpg)
            var logoGo = new GameObject("Logo3DImage", typeof(RectTransform), typeof(Image));
            logoGo.transform.SetParent(menuModalObj.transform, false);
            var logoRt = logoGo.GetComponent<RectTransform>();
            logoRt.anchorMin = new Vector2(0, 1);
            logoRt.anchorMax = new Vector2(0, 1);
            logoRt.pivot = new Vector2(0, 1);
            logoRt.anchoredPosition = new Vector2(48, -200);
            logoRt.sizeDelta = new Vector2(480, 280);
            var logoImg = logoGo.GetComponent<Image>();
            logoImg.sprite = Resources.Load<Sprite>("UI/title_logo_3d");
            logoImg.preserveAspect = true;

            // Top-Left Settings Gear Icon
            var gearBtnObj = new GameObject("TopSettingsBtn", typeof(RectTransform), typeof(Image), typeof(Button));
            gearBtnObj.transform.SetParent(menuModalObj.transform, false);
            var gearRt = gearBtnObj.GetComponent<RectTransform>();
            gearRt.anchorMin = new Vector2(0, 1);
            gearRt.anchorMax = new Vector2(0, 1);
            gearRt.pivot = new Vector2(0, 1);
            gearRt.anchoredPosition = new Vector2(48, -36);
            gearRt.sizeDelta = new Vector2(54, 54);
            var gearImg = gearBtnObj.GetComponent<Image>();
            gearImg.sprite = pillNavy;
            gearImg.type = Image.Type.Sliced;

            var gearIconObj = new GameObject("Icon", typeof(RectTransform), typeof(Image));
            gearIconObj.transform.SetParent(gearBtnObj.transform, false);
            var giRt = gearIconObj.GetComponent<RectTransform>();
            giRt.anchorMin = new Vector2(0.5f, 0.5f);
            giRt.anchorMax = new Vector2(0.5f, 0.5f);
            giRt.pivot = new Vector2(0.5f, 0.5f);
            giRt.anchoredPosition = Vector2.zero;
            giRt.sizeDelta = new Vector2(34, 34);
            var giImg = gearIconObj.GetComponent<Image>();
            giImg.sprite = Resources.Load<Sprite>("UI/icon_settings");
            giImg.preserveAspect = true;

            // Top-Right Language Pill
            var langBtnObj = new GameObject("TopLangBtn", typeof(RectTransform), typeof(Image), typeof(Button));
            langBtnObj.transform.SetParent(menuModalObj.transform, false);
            var langRt = langBtnObj.GetComponent<RectTransform>();
            langRt.anchorMin = new Vector2(1, 1);
            langRt.anchorMax = new Vector2(1, 1);
            langRt.pivot = new Vector2(1, 1);
            langRt.anchoredPosition = new Vector2(-48, -36);
            langRt.sizeDelta = new Vector2(130, 54);
            var langImg = langBtnObj.GetComponent<Image>();
            langImg.sprite = pillNavy;
            langImg.type = Image.Type.Sliced;

            var langFlagObj = new GameObject("Flag", typeof(RectTransform), typeof(Image));
            langFlagObj.transform.SetParent(langBtnObj.transform, false);
            var lfRt = langFlagObj.GetComponent<RectTransform>();
            lfRt.anchorMin = new Vector2(0, 0.5f);
            lfRt.anchorMax = new Vector2(0, 0.5f);
            lfRt.pivot = new Vector2(0, 0.5f);
            lfRt.anchoredPosition = new Vector2(12, 0);
            lfRt.sizeDelta = new Vector2(32, 22);
            var lfImg = langFlagObj.GetComponent<Image>();
            lfImg.sprite = Resources.Load<Sprite>("Flags/png/RU") ?? Resources.Load<Sprite>("Flags/RU");

            var langTxt = CreateText("Label", langBtnObj.transform, font, 20, TextAnchor.MiddleCenter, Color.white);
            var ltrt = langTxt.GetComponent<RectTransform>();
            ltrt.anchorMin = Vector2.zero;
            ltrt.anchorMax = Vector2.one;
            ltrt.offsetMin = new Vector2(46, 0);
            ltrt.offsetMax = new Vector2(-8, 0);
            var ltComp = langTxt.GetComponent<Text>();
            ltComp.fontStyle = FontStyle.Bold;
            ltComp.text = "RU";

            // 5 Chunky Rounded Buttons Framing the Left of the Sunny 3D Scene
            Vector2 menuBtnSize = new Vector2(460, 115);
            float btnLeftX = 48f;

            var btnPlay = CreateMenuButtonWithIcon("PlayBtn", menuModalObj.transform, btnGreen, "UI/icon_play", font, "ИГРАТЬ", btnLeftX, -780f, menuBtnSize, 30);
            menuModals.PlayButton = btnPlay.Btn;
            menuModals.PlayButtonText = btnPlay.Txt;

            var btnMaps = CreateMenuButtonWithIcon("MapsBtn", menuModalObj.transform, btnBlue, "UI/icon_map", font, "ВЫБОР КАРТЫ", btnLeftX, -950f, menuBtnSize, 28);
            menuModals.OpenMapsButton = btnMaps.Btn;
            menuModals.OpenMapsButtonText = btnMaps.Txt;

            var btnShop = CreateMenuButtonWithIcon("ShopBtn", menuModalObj.transform, btnOrange, "UI/icon_shop", font, "МАГАЗИН", btnLeftX, -1120f, menuBtnSize, 30);
            menuModals.OpenShopButton = btnShop.Btn;
            menuModals.OpenShopButtonText = btnShop.Txt;

            // Red ! badge on Shop button
            var badgeObj = new GameObject("NotifBadge", typeof(RectTransform), typeof(Image));
            badgeObj.transform.SetParent(btnShop.Btn.transform, false);
            var badgeRt = badgeObj.GetComponent<RectTransform>();
            badgeRt.anchorMin = new Vector2(1, 1);
            badgeRt.anchorMax = new Vector2(1, 1);
            badgeRt.pivot = new Vector2(0.5f, 0.5f);
            badgeRt.anchoredPosition = new Vector2(-14, -10);
            badgeRt.sizeDelta = new Vector2(44, 44);
            var badgeImg = badgeObj.GetComponent<Image>();
            badgeImg.sprite = badgeExcl;
            badgeImg.color = Color.white;

            var btnDaily = CreateMenuButtonWithIcon("DailyBtn", menuModalObj.transform, btnPurple, "UI/icon_trophy", font, "ЕЖЕДНЕВНЫЕ НАГРАДЫ", btnLeftX, -1290f, menuBtnSize, 24);
            menuModals.OpenDailyButton = btnDaily.Btn;
            menuModals.OpenDailyButtonText = btnDaily.Txt;

            var btnSettings = CreateMenuButtonWithIcon("SettingsBtn", menuModalObj.transform, btnSlate, "UI/icon_settings", font, "НАСТРОЙКИ", btnLeftX, -1460f, menuBtnSize, 28);
            menuModals.OpenSettingsButton = btnSettings.Btn;
            menuModals.OpenSettingsButtonText = btnSettings.Txt;

            // 2. Shop Modal
            var shopModalObj = CreateModalRoot("ShopModal", hudObj.transform);
            menuModals.ShopPanel = shopModalObj;
            var shopDialog = CreateDialogWindow("Dialog", shopModalObj.transform, panelDialog, new Vector2(600, 850));
            var shopTitle = CreateText("Title", shopDialog.transform, font, 28, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            SetRect(shopTitle.GetComponent<RectTransform>(), new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, -20), new Vector2(0, 45));
            menuModals.ShopTitleText = shopTitle.GetComponent<Text>();
            menuModals.CloseShopButton = CreateCloseButton(shopDialog.transform, panelDialog, font);
            menuModals.ShopContent = CreateScrollContainer(shopDialog.transform, font);

            // 3. Daily Rewards Modal
            var dailyModalObj = CreateModalRoot("DailyRewardModal", hudObj.transform);
            menuModals.DailyRewardPanel = dailyModalObj;
            var dailyDialog = CreateDialogWindow("Dialog", dailyModalObj.transform, panelDialog, new Vector2(560, 750));
            var dailyTitle = CreateText("Title", dailyDialog.transform, font, 28, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            SetRect(dailyTitle.GetComponent<RectTransform>(), new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, -20), new Vector2(0, 45));
            menuModals.DailyTitleText = dailyTitle.GetComponent<Text>();
            menuModals.CloseDailyButton = CreateCloseButton(dailyDialog.transform, panelDialog, font);
            menuModals.DailyContent = CreateScrollContainer(dailyDialog.transform, font);

            // 4. Map Select Modal
            var mapsModalObj = CreateModalRoot("MapSelectModal", hudObj.transform);
            menuModals.MapSelectPanel = mapsModalObj;
            var mapsDialog = CreateDialogWindow("Dialog", mapsModalObj.transform, panelDialog, new Vector2(580, 800));
            var mapsTitle = CreateText("Title", mapsDialog.transform, font, 28, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            SetRect(mapsTitle.GetComponent<RectTransform>(), new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, -20), new Vector2(0, 45));
            menuModals.MapsTitleText = mapsTitle.GetComponent<Text>();
            menuModals.CloseMapsButton = CreateCloseButton(mapsDialog.transform, panelDialog, font);
            menuModals.MapsContent = CreateScrollContainer(mapsDialog.transform, font);

            // 5. Settings Modal
            var settingsModalObj = CreateModalRoot("SettingsModal", hudObj.transform);
            menuModals.SettingsPanel = settingsModalObj;
            var settingsDialog = CreateDialogWindow("Dialog", settingsModalObj.transform, panelDialog, new Vector2(560, 720));
            var settingsTitle = CreateText("Title", settingsDialog.transform, font, 28, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            SetRect(settingsTitle.GetComponent<RectTransform>(), new Vector2(0, 1), new Vector2(1, 1), new Vector2(0.5f, 1), new Vector2(0, -20), new Vector2(0, 45));
            menuModals.SettingsTitleText = settingsTitle.GetComponent<Text>();
            menuModals.CloseSettingsButton = CreateCloseButton(settingsDialog.transform, panelDialog, font);

            // Settings Controls
            var btnLang = CreateModalButton("LangSettingBtn", settingsDialog.transform, btnBlue, font, "ЯЗЫК: РУССКИЙ", new Vector2(0, 140), Color.white);
            menuModals.SettingsLangButton = btnLang.Btn;
            menuModals.SettingsLangButtonText = btnLang.Txt;

            var btnSound = CreateModalButton("SoundSettingBtn", settingsDialog.transform, btnSlate, font, "ЗВУК: ВКЛ", new Vector2(0, 65), Color.white);
            menuModals.SettingsSoundButton = btnSound.Btn;
            menuModals.SettingsSoundButtonText = btnSound.Txt;

            var btnMusic = CreateModalButton("MusicSettingBtn", settingsDialog.transform, btnSlate, font, "МУЗЫКА: ВКЛ", new Vector2(0, -10), Color.white);
            menuModals.SettingsMusicButton = btnMusic.Btn;
            menuModals.SettingsMusicButtonText = btnMusic.Txt;

            // About Box Container
            var aboutBox = new GameObject("AboutBox", typeof(RectTransform), typeof(Image));
            aboutBox.transform.SetParent(settingsDialog.transform, false);
            var aboutRt = aboutBox.GetComponent<RectTransform>();
            aboutRt.anchorMin = new Vector2(0.5f, 0.5f);
            aboutRt.anchorMax = new Vector2(0.5f, 0.5f);
            aboutRt.anchoredPosition = new Vector2(0, -155);
            aboutRt.sizeDelta = new Vector2(460, 180);
            var aboutImg = aboutBox.GetComponent<Image>();
            aboutImg.sprite = pillNavy;
            aboutImg.type = Image.Type.Sliced;
            aboutImg.color = new Color(0.06f, 0.09f, 0.14f, 0.95f);

            var aboutTitle = CreateText("AboutTitle", aboutBox.transform, font, 20, TextAnchor.MiddleCenter, new Color(1f, 0.85f, 0.2f));
            var atRt = aboutTitle.GetComponent<RectTransform>();
            atRt.anchorMin = new Vector2(0, 1);
            atRt.anchorMax = new Vector2(1, 1);
            atRt.pivot = new Vector2(0.5f, 1);
            atRt.anchoredPosition = new Vector2(0, -12);
            atRt.sizeDelta = new Vector2(0, 30);
            menuModals.AboutTitleText = aboutTitle.GetComponent<Text>();

            var aboutVer = CreateText("AboutVersion", aboutBox.transform, font, 17, TextAnchor.MiddleCenter, Color.white);
            var avRt = aboutVer.GetComponent<RectTransform>();
            avRt.anchorMin = Vector2.zero;
            avRt.anchorMax = Vector2.one;
            avRt.offsetMin = new Vector2(15, 10);
            avRt.offsetMax = new Vector2(-15, -45);
            menuModals.AboutVersionText = aboutVer.GetComponent<Text>();
        }

        private static GameObject CreateModalRoot(string name, Transform parent)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = Vector2.zero;
            rt.anchorMax = Vector2.one;
            rt.offsetMin = Vector2.zero;
            rt.offsetMax = Vector2.zero;
            go.GetComponent<Image>().color = new Color(0, 0, 0, 0.70f);
            return go;
        }

        private static GameObject CreateDialogWindow(string name, Transform parent, Sprite uiSprite, Vector2 size)
        {
            var go = new GameObject(name, typeof(RectTransform), typeof(Image));
            go.transform.SetParent(parent, false);
            var rt = go.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.sizeDelta = size;
            var img = go.GetComponent<Image>();
            img.sprite = uiSprite;
            img.type = Image.Type.Sliced;
            img.color = new Color(0.10f, 0.14f, 0.22f, 0.98f);
            return go;
        }

        private static Button CreateCloseButton(Transform parent, Sprite uiSprite, Font font)
        {
            var btnObj = new GameObject("CloseBtn", typeof(RectTransform), typeof(Image), typeof(Button));
            btnObj.transform.SetParent(parent, false);
            var rt = btnObj.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(1, 1);
            rt.anchorMax = new Vector2(1, 1);
            rt.pivot = new Vector2(1, 1);
            rt.anchoredPosition = new Vector2(-15, -15);
            rt.sizeDelta = new Vector2(50, 50);
            var img = btnObj.GetComponent<Image>();
            img.sprite = uiSprite;
            img.type = Image.Type.Sliced;
            img.color = new Color(0.75f, 0.2f, 0.2f);

            var lbl = CreateText("X", btnObj.transform, font, 24, TextAnchor.MiddleCenter, Color.white);
            var lrt = lbl.GetComponent<RectTransform>();
            lrt.anchorMin = Vector2.zero;
            lrt.anchorMax = Vector2.one;
            lrt.offsetMin = Vector2.zero;
            lrt.offsetMax = Vector2.zero;

            return btnObj.GetComponent<Button>();
        }

        private static (Button Btn, Text Txt) CreateMenuButtonWithIcon(string name, Transform parent, Sprite uiSprite, string iconResPath, Font font, string label, float posX, float posY, Vector2 size, int fontSize = 22)
        {
            var btnObj = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            btnObj.transform.SetParent(parent, false);
            var rt = btnObj.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0, 1);
            rt.anchorMax = new Vector2(0, 1);
            rt.pivot = new Vector2(0, 1);
            rt.anchoredPosition = new Vector2(posX, posY);
            rt.sizeDelta = size;
            var img = btnObj.GetComponent<Image>();
            img.sprite = uiSprite;
            img.type = Image.Type.Sliced;
            img.color = Color.white;

            if (!string.IsNullOrEmpty(iconResPath))
            {
                var iconObj = new GameObject("BtnIcon", typeof(RectTransform), typeof(Image));
                iconObj.transform.SetParent(btnObj.transform, false);
                var iconRt = iconObj.GetComponent<RectTransform>();
                iconRt.anchorMin = new Vector2(0, 0.5f);
                iconRt.anchorMax = new Vector2(0, 0.5f);
                iconRt.pivot = new Vector2(0, 0.5f);
                iconRt.anchoredPosition = new Vector2(24, 0);
                iconRt.sizeDelta = new Vector2(68, 68);
                var iconImg = iconObj.GetComponent<Image>();
                iconImg.sprite = Resources.Load<Sprite>(iconResPath);
                iconImg.preserveAspect = true;
                iconImg.color = Color.white;
            }

            var txtObj = CreateText("Label", btnObj.transform, font, fontSize, TextAnchor.MiddleCenter, Color.white);
            var trt = txtObj.GetComponent<RectTransform>();
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = new Vector2(100, 0);
            trt.offsetMax = new Vector2(-20, 0);
            var txt = txtObj.GetComponent<Text>();
            txt.text = label;
            txt.fontStyle = FontStyle.Bold;

            var shadow = txtObj.AddComponent<Shadow>();
            shadow.effectColor = new Color(0, 0, 0, 0.65f);
            shadow.effectDistance = new Vector2(2, -2);

            return (btnObj.GetComponent<Button>(), txt);
        }

        private static (Button Btn, Text Txt) CreateModalButton(string name, Transform parent, Sprite uiSprite, Font font, string label, Vector2 pos, Color col, Vector2? customSize = null, int fontSize = 22)
        {
            var btnObj = new GameObject(name, typeof(RectTransform), typeof(Image), typeof(Button));
            btnObj.transform.SetParent(parent, false);
            var rt = btnObj.GetComponent<RectTransform>();
            rt.anchorMin = new Vector2(0.5f, 0.5f);
            rt.anchorMax = new Vector2(0.5f, 0.5f);
            rt.anchoredPosition = pos;
            rt.sizeDelta = customSize ?? new Vector2(340, 65);
            var img = btnObj.GetComponent<Image>();
            img.sprite = uiSprite;
            img.type = Image.Type.Sliced;
            img.color = col;

            var txtObj = CreateText("Label", btnObj.transform, font, fontSize, TextAnchor.MiddleCenter, Color.white);
            var trt = txtObj.GetComponent<RectTransform>();
            trt.anchorMin = Vector2.zero;
            trt.anchorMax = Vector2.one;
            trt.offsetMin = Vector2.zero;
            trt.offsetMax = Vector2.zero;
            var txt = txtObj.GetComponent<Text>();
            txt.text = label;
            txt.fontStyle = FontStyle.Bold;

            return (btnObj.GetComponent<Button>(), txt);
        }

        private static Transform CreateScrollContainer(Transform parent, Font font)
        {
            var scrollObj = new GameObject("ScrollView", typeof(RectTransform), typeof(ScrollRect), typeof(Image));
            scrollObj.transform.SetParent(parent, false);
            var scrollRt = scrollObj.GetComponent<RectTransform>();
            scrollRt.anchorMin = Vector2.zero;
            scrollRt.anchorMax = Vector2.one;
            scrollRt.offsetMin = new Vector2(20, 20);
            scrollRt.offsetMax = new Vector2(-20, -75);
            scrollObj.GetComponent<Image>().color = new Color(0.06f, 0.08f, 0.12f, 0.6f);

            var scroll = scrollObj.GetComponent<ScrollRect>();
            scroll.horizontal = false;
            scroll.vertical = true;

            var vpObj = new GameObject("Viewport", typeof(RectTransform), typeof(Mask), typeof(Image));
            vpObj.transform.SetParent(scrollObj.transform, false);
            var vpRt = vpObj.GetComponent<RectTransform>();
            vpRt.anchorMin = Vector2.zero;
            vpRt.anchorMax = Vector2.one;
            vpRt.offsetMin = Vector2.zero;
            vpRt.offsetMax = Vector2.zero;
            vpObj.GetComponent<Mask>().showMaskGraphic = false;

            var contentObj = new GameObject("Content", typeof(RectTransform), typeof(VerticalLayoutGroup), typeof(ContentSizeFitter));
            contentObj.transform.SetParent(vpObj.transform, false);
            var contentRt = contentObj.GetComponent<RectTransform>();
            contentRt.anchorMin = new Vector2(0, 1);
            contentRt.anchorMax = new Vector2(1, 1);
            contentRt.pivot = new Vector2(0.5f, 1);

            var vlg = contentObj.GetComponent<VerticalLayoutGroup>();
            vlg.spacing = 10;
            vlg.padding = new RectOffset(10, 10, 10, 10);
            vlg.childForceExpandWidth = true;
            vlg.childForceExpandHeight = false;
            vlg.childControlWidth = true;
            vlg.childControlHeight = false;

            var csf = contentObj.GetComponent<ContentSizeFitter>();
            csf.verticalFit = ContentSizeFitter.FitMode.PreferredSize;

            scroll.viewport = vpRt;
            scroll.content = contentRt;

            return contentRt;
        }

        private static void SetRect(RectTransform rt, Vector2 aMin, Vector2 aMax, Vector2 pivot, Vector2 pos, Vector2 size)
        {
            rt.anchorMin = aMin;
            rt.anchorMax = aMax;
            rt.pivot = pivot;
            rt.anchoredPosition = pos;
            rt.sizeDelta = size;
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
            txt.horizontalOverflow = HorizontalWrapMode.Wrap;
            txt.verticalOverflow = VerticalWrapMode.Overflow;
            return go;
        }
    }
}
#endif
