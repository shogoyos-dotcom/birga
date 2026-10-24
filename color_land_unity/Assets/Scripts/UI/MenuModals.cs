using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.App;

namespace ColorLand.UI
{
    /// <summary>
    /// Color Land 3D — Asosiy menyu, do'kon, xaritalar va kunlik mukofotlar modallari (MenuModals).
    /// Barcha 15 ta tilni, xususan to'liq rus tilini qo'llab-quvvatlaydi.
    /// Matnlar, narxlar va tavsiflar qulay va o'qishli shriftlarda taqdim etiladi.
    /// </summary>
    public class MenuModals : MonoBehaviour
    {
        public static MenuModals Instance { get; private set; }

        [Header("Modals")]
        public GameObject MainMenuPanel;
        public GameObject ShopPanel;
        public GameObject DailyRewardPanel;
        public GameObject MapSelectPanel;
        public GameObject SettingsPanel;

        [Header("Main Menu Elements")]
        public Text MenuTitleText;
        public Button PlayButton;
        public Text PlayButtonText;
        public Button OpenShopButton;
        public Text OpenShopButtonText;
        public Button OpenMapsButton;
        public Text OpenMapsButtonText;
        public Button OpenDailyButton;
        public Text OpenDailyButtonText;
        public Button OpenSettingsButton;
        public Text OpenSettingsButtonText;
        public Button CloseMenuButton;

        [Header("Settings Elements")]
        public Text SettingsTitleText;
        public Button CloseSettingsButton;
        public Button SettingsLangButton;
        public Text SettingsLangButtonText;
        public Button SettingsSoundButton;
        public Text SettingsSoundButtonText;
        public Button SettingsMusicButton;
        public Text SettingsMusicButtonText;
        public Text AboutTitleText;
        public Text AboutVersionText;

        [Header("Shop Elements")]
        public Text ShopTitleText;
        public Transform ShopContent;
        public Button CloseShopButton;

        [Header("Daily Reward Elements")]
        public Text DailyTitleText;
        public Transform DailyContent;
        public Button CloseDailyButton;

        [Header("Map Select Elements")]
        public Text MapsTitleText;
        public Transform MapsContent;
        public Button CloseMapsButton;

        private void Awake()
        {
            Instance = this;
            SetupListeners();
        }

        private void Start()
        {
            Strings.OnLanguageChanged += RefreshAllTexts;
            RefreshAllTexts();
            PopulateShop();
            PopulateDailyRewards();
            PopulateMaps();

            // Boshlang'ichda modallar yopiq
            if (MainMenuPanel != null) MainMenuPanel.SetActive(false);
            if (ShopPanel != null) ShopPanel.SetActive(false);
            if (DailyRewardPanel != null) DailyRewardPanel.SetActive(false);
            if (MapSelectPanel != null) MapSelectPanel.SetActive(false);
            if (SettingsPanel != null) SettingsPanel.SetActive(false);
        }

        private void OnDestroy()
        {
            Strings.OnLanguageChanged -= RefreshAllTexts;
        }

        private void SetupListeners()
        {
            if (CloseMenuButton != null) CloseMenuButton.onClick.AddListener(() => MainMenuPanel.SetActive(false));
            if (CloseShopButton != null) CloseShopButton.onClick.AddListener(() => ShopPanel.SetActive(false));
            if (CloseDailyButton != null) CloseDailyButton.onClick.AddListener(() => DailyRewardPanel.SetActive(false));
            if (CloseMapsButton != null) CloseMapsButton.onClick.AddListener(() => MapSelectPanel.SetActive(false));
            if (CloseSettingsButton != null) CloseSettingsButton.onClick.AddListener(() => SettingsPanel.SetActive(false));

            if (OpenShopButton != null) OpenShopButton.onClick.AddListener(ShowShop);
            if (OpenMapsButton != null) OpenMapsButton.onClick.AddListener(ShowMaps);
            if (OpenDailyButton != null) OpenDailyButton.onClick.AddListener(ShowDailyRewards);
            if (OpenSettingsButton != null) OpenSettingsButton.onClick.AddListener(ShowSettings);
            if (PlayButton != null) PlayButton.onClick.AddListener(() => MainMenuPanel.SetActive(false));

            if (SettingsLangButton != null) SettingsLangButton.onClick.AddListener(OpenLanguagePicker);
            if (SettingsSoundButton != null) SettingsSoundButton.onClick.AddListener(ToggleSound);
            if (SettingsMusicButton != null) SettingsMusicButton.onClick.AddListener(ToggleMusic);
        }

        private void OpenLanguagePicker()
        {
            if (LanguagePickerModal.Instance != null)
            {
                LanguagePickerModal.Instance.Show();
            }
        }

        private void ToggleSound()
        {
            SaveManager.Current.SoundEnabled = !SaveManager.Current.SoundEnabled;
            SaveManager.Save();
            UpdateSettingsUI();
        }

        private void ToggleMusic()
        {
            SaveManager.Current.MusicEnabled = !SaveManager.Current.MusicEnabled;
            SaveManager.Save();
            UpdateSettingsUI();
        }

        public void ShowMainMenu()
        {
            HideAll();
            if (MainMenuPanel != null) MainMenuPanel.SetActive(true);
            RefreshAllTexts();
        }

        public void ShowShop()
        {
            HideAll();
            if (ShopPanel != null) ShopPanel.SetActive(true);
            PopulateShop();
        }

        public void ShowDailyRewards()
        {
            HideAll();
            if (DailyRewardPanel != null) DailyRewardPanel.SetActive(true);
            PopulateDailyRewards();
        }

        public void ShowMaps()
        {
            HideAll();
            if (MapSelectPanel != null) MapSelectPanel.SetActive(true);
            PopulateMaps();
        }

        public void ShowSettings()
        {
            HideAll();
            if (SettingsPanel != null) SettingsPanel.SetActive(true);
            UpdateSettingsUI();
        }

        public void HideAll()
        {
            if (MainMenuPanel != null) MainMenuPanel.SetActive(false);
            if (ShopPanel != null) ShopPanel.SetActive(false);
            if (DailyRewardPanel != null) DailyRewardPanel.SetActive(false);
            if (MapSelectPanel != null) MapSelectPanel.SetActive(false);
            if (SettingsPanel != null) SettingsPanel.SetActive(false);
        }

        public void RefreshAllTexts()
        {
            if (MenuTitleText != null) MenuTitleText.text = Strings.T("menu").ToUpperInvariant();
            if (PlayButtonText != null) PlayButtonText.text = Strings.T("play").ToUpperInvariant();
            if (OpenShopButtonText != null) OpenShopButtonText.text = Strings.T("shopTitle").ToUpperInvariant();
            if (OpenMapsButtonText != null) OpenMapsButtonText.text = Strings.T("mapSelect").ToUpperInvariant();
            if (OpenDailyButtonText != null) OpenDailyButtonText.text = Strings.T("dailyReward").ToUpperInvariant();
            if (OpenSettingsButtonText != null) OpenSettingsButtonText.text = Strings.T("settings", "НАСТРОЙКИ").ToUpperInvariant();

            if (ShopTitleText != null) ShopTitleText.text = Strings.T("shopTitle").ToUpperInvariant();
            if (DailyTitleText != null) DailyTitleText.text = Strings.T("dailyReward").ToUpperInvariant();
            if (MapsTitleText != null) MapsTitleText.text = Strings.T("mapSelect").ToUpperInvariant();
            if (SettingsTitleText != null) SettingsTitleText.text = Strings.T("settings", "НАСТРОЙКИ").ToUpperInvariant();

            UpdateSettingsUI();
        }

        private void UpdateSettingsUI()
        {
            if (AboutTitleText != null)
            {
                AboutTitleText.text = Strings.T("about", "ОБ ИГРЕ").ToUpperInvariant();
            }
            if (AboutVersionText != null)
            {
                AboutVersionText.text = VersionConfig.GetAboutDisplay();
            }

            string currentNativeLang = Strings.CurrentLanguage.ToUpperInvariant();
            foreach (var l in Strings.SupportedLanguages)
            {
                if (l.Code.Equals(Strings.CurrentLanguage, StringComparison.OrdinalIgnoreCase))
                {
                    currentNativeLang = l.NativeName;
                    break;
                }
            }

            if (SettingsLangButtonText != null)
            {
                SettingsLangButtonText.text = $"{Strings.T("language", "ЯЗЫК")}: {currentNativeLang}";
            }

            bool snd = SaveManager.Current.SoundEnabled;
            string onStr = Strings.T("stateOn", "ВКЛ");
            string offStr = Strings.T("stateOff", "ВЫКЛ");

            if (SettingsSoundButtonText != null)
            {
                SettingsSoundButtonText.text = $"{Strings.T("sound", "ЗВУК")}: {(snd ? onStr : offStr)}";
            }

            bool mus = SaveManager.Current.MusicEnabled;
            if (SettingsMusicButtonText != null)
            {
                SettingsMusicButtonText.text = $"{Strings.T("music", "МУЗЫКА")}: {(mus ? onStr : offStr)}";
            }
        }

        public void PopulateShop()
        {
            if (ShopContent == null) return;
            foreach (Transform child in ShopContent) Destroy(child.gameObject);

            Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");
            Sprite cardSprite = Resources.Load<Sprite>("UI/rounded_rect");

            // Do'kon qahramonlari va terilari
            var shopItems = new[]
            {
                new { NameKey = "skinNeon", Desc = "Неоновое сияние и скорость", Price = 500, Color = new Color(0.1f, 0.9f, 0.9f) },
                new { NameKey = "skinMagma", Desc = "Огненный шлейф магмы", Price = 800, Color = new Color(0.95f, 0.35f, 0.1f) },
                new { NameKey = "heroGolem", Desc = "Могучий каменный голем", Price = 1200, Color = new Color(0.6f, 0.6f, 0.65f) },
                new { NameKey = "heroPenguin", Desc = "Быстрый арктический пингвин", Price = 1500, Color = new Color(0.2f, 0.5f, 0.9f) },
                new { NameKey = "skinGalaxy", Desc = "Космическая туманность", Price = 2000, Color = new Color(0.65f, 0.2f, 0.85f) }
            };

            foreach (var item in shopItems)
            {
                var row = new GameObject($"Item_{item.NameKey}", typeof(RectTransform), typeof(Image));
                row.transform.SetParent(ShopContent, false);
                row.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 75);
                var img = row.GetComponent<Image>();
                img.sprite = cardSprite;
                img.type = Image.Type.Sliced;
                img.color = new Color(0.14f, 0.18f, 0.26f, 0.95f);

                // Icon / Color preview
                var iconObj = new GameObject("Icon", typeof(RectTransform), typeof(Image));
                iconObj.transform.SetParent(row.transform, false);
                var iconRt = iconObj.GetComponent<RectTransform>();
                iconRt.anchorMin = new Vector2(0, 0.5f);
                iconRt.anchorMax = new Vector2(0, 0.5f);
                iconRt.anchoredPosition = new Vector2(35, 0);
                iconRt.sizeDelta = new Vector2(45, 45);
                iconObj.GetComponent<Image>().color = item.Color;

                // Title & Desc
                var textObj = new GameObject("Details", typeof(RectTransform), typeof(Text));
                textObj.transform.SetParent(row.transform, false);
                var textRt = textObj.GetComponent<RectTransform>();
                textRt.anchorMin = new Vector2(0, 0);
                textRt.anchorMax = new Vector2(0.7f, 1);
                textRt.offsetMin = new Vector2(75, 5);
                textRt.offsetMax = new Vector2(0, -5);
                var txt = textObj.GetComponent<Text>();
                txt.font = font;
                txt.fontSize = 18;
                txt.color = Color.white;
                txt.alignment = TextAnchor.MiddleLeft;
                string title = Strings.T(item.NameKey);
                txt.text = $"<b>{title}</b>\n<size=14><color=#94a3b8>{item.Desc}</color></size>";

                // Price Tag / Button
                var btnObj = new GameObject("BuyBtn", typeof(RectTransform), typeof(Image), typeof(Button));
                btnObj.transform.SetParent(row.transform, false);
                var btnRt = btnObj.GetComponent<RectTransform>();
                btnRt.anchorMin = new Vector2(1, 0.5f);
                btnRt.anchorMax = new Vector2(1, 0.5f);
                btnRt.pivot = new Vector2(1, 0.5f);
                btnRt.anchoredPosition = new Vector2(-15, 0);
                btnRt.sizeDelta = new Vector2(130, 48);
                var btnImg = btnObj.GetComponent<Image>();
                btnImg.sprite = cardSprite;
                btnImg.type = Image.Type.Sliced;
                btnImg.color = new Color(0.16f, 0.65f, 0.35f);

                var priceObj = new GameObject("Price", typeof(RectTransform), typeof(Text));
                priceObj.transform.SetParent(btnObj.transform, false);
                var priceRt = priceObj.GetComponent<RectTransform>();
                priceRt.anchorMin = Vector2.zero;
                priceRt.anchorMax = Vector2.one;
                priceRt.offsetMin = Vector2.zero;
                priceRt.offsetMax = Vector2.zero;
                var pTxt = priceObj.GetComponent<Text>();
                pTxt.font = font;
                pTxt.fontSize = 16;
                pTxt.color = Color.white;
                pTxt.fontStyle = FontStyle.Bold;
                pTxt.alignment = TextAnchor.MiddleCenter;
                pTxt.text = $"{item.Price} 🪙";
            }
        }

        public void PopulateDailyRewards()
        {
            if (DailyContent == null) return;
            foreach (Transform child in DailyContent) Destroy(child.gameObject);

            Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");
            Sprite cardSprite = Resources.Load<Sprite>("UI/rounded_rect");

            for (int day = 1; day <= 7; day++)
            {
                int reward = day * 100;
                bool isFinal = (day == 7);

                var card = new GameObject($"Day_{day}", typeof(RectTransform), typeof(Image));
                card.transform.SetParent(DailyContent, false);
                card.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 60);
                var img = card.GetComponent<Image>();
                img.sprite = cardSprite;
                img.type = Image.Type.Sliced;
                img.color = isFinal ? new Color(0.35f, 0.25f, 0.05f, 0.95f) : new Color(0.12f, 0.16f, 0.24f, 0.9f);

                var txtObj = new GameObject("Text", typeof(RectTransform), typeof(Text));
                txtObj.transform.SetParent(card.transform, false);
                var trt = txtObj.GetComponent<RectTransform>();
                trt.anchorMin = Vector2.zero;
                trt.anchorMax = new Vector2(0.7f, 1);
                trt.offsetMin = new Vector2(20, 0);
                trt.offsetMax = Vector2.zero;

                var txt = txtObj.GetComponent<Text>();
                txt.font = font;
                txt.fontSize = 18;
                txt.color = isFinal ? Color.yellow : Color.white;
                txt.alignment = TextAnchor.MiddleLeft;
                string dayPrefix = Strings.CurrentLanguage == "ru" ? "День" : (Strings.CurrentLanguage == "uz" ? "Kun" : "Day");
                txt.text = $"{dayPrefix} {day}: +{reward} 🪙" + (isFinal ? " 🎁" : "");

                // Claim Button
                var btnObj = new GameObject("ClaimBtn", typeof(RectTransform), typeof(Image), typeof(Button));
                btnObj.transform.SetParent(card.transform, false);
                var brt = btnObj.GetComponent<RectTransform>();
                brt.anchorMin = new Vector2(1, 0.5f);
                brt.anchorMax = new Vector2(1, 0.5f);
                brt.pivot = new Vector2(1, 0.5f);
                brt.anchoredPosition = new Vector2(-15, 0);
                brt.sizeDelta = new Vector2(110, 42);
                var bimg = btnObj.GetComponent<Image>();
                bimg.sprite = cardSprite;
                bimg.type = Image.Type.Sliced;
                bimg.color = day == 1 ? new Color(0.18f, 0.72f, 0.35f) : new Color(0.3f, 0.35f, 0.42f);

                var btxtObj = new GameObject("Label", typeof(RectTransform), typeof(Text));
                btxtObj.transform.SetParent(btnObj.transform, false);
                var btrt = btxtObj.GetComponent<RectTransform>();
                btrt.anchorMin = Vector2.zero;
                btrt.anchorMax = Vector2.one;
                btrt.offsetMin = Vector2.zero;
                btrt.offsetMax = Vector2.zero;
                var btxt = btxtObj.GetComponent<Text>();
                btxt.font = font;
                btxt.fontSize = 15;
                btxt.color = Color.white;
                btxt.alignment = TextAnchor.MiddleCenter;
                btxt.text = day == 1 ? Strings.T("claim") : (day < 1 ? Strings.T("claimed") : $"{day} d");
            }
        }

        public void PopulateMaps()
        {
            if (MapsContent == null) return;
            foreach (Transform child in MapsContent) Destroy(child.gameObject);

            Font font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");
            Sprite cardSprite = Resources.Load<Sprite>("UI/rounded_rect");

            var mapKeys = new[]
            {
                new { Key = "mapWorld", Color = new Color(0.2f, 0.6f, 0.9f) },
                new { Key = "mapEurope", Color = new Color(0.3f, 0.75f, 0.4f) },
                new { Key = "mapAsia", Color = new Color(0.9f, 0.65f, 0.2f) },
                new { Key = "mapAfrica", Color = new Color(0.85f, 0.4f, 0.2f) },
                new { Key = "mapNorthAmerica", Color = new Color(0.3f, 0.45f, 0.85f) },
                new { Key = "mapSouthAmerica", Color = new Color(0.25f, 0.7f, 0.55f) },
                new { Key = "mapOceania", Color = new Color(0.6f, 0.35f, 0.8f) }
            };

            foreach (var m in mapKeys)
            {
                var card = new GameObject($"Map_{m.Key}", typeof(RectTransform), typeof(Image));
                card.transform.SetParent(MapsContent, false);
                card.GetComponent<RectTransform>().sizeDelta = new Vector2(0, 65);
                var img = card.GetComponent<Image>();
                img.sprite = cardSprite;
                img.type = Image.Type.Sliced;
                img.color = new Color(0.12f, 0.16f, 0.24f, 0.95f);

                var txtObj = new GameObject("MapName", typeof(RectTransform), typeof(Text));
                txtObj.transform.SetParent(card.transform, false);
                var trt = txtObj.GetComponent<RectTransform>();
                trt.anchorMin = Vector2.zero;
                trt.anchorMax = new Vector2(0.7f, 1);
                trt.offsetMin = new Vector2(25, 0);
                trt.offsetMax = Vector2.zero;
                var txt = txtObj.GetComponent<Text>();
                txt.font = font;
                txt.fontSize = 20;
                txt.color = m.Color;
                txt.fontStyle = FontStyle.Bold;
                txt.alignment = TextAnchor.MiddleLeft;
                txt.text = Strings.T(m.Key);

                // Select Button
                var btnObj = new GameObject("SelectBtn", typeof(RectTransform), typeof(Image), typeof(Button));
                btnObj.transform.SetParent(card.transform, false);
                var brt = btnObj.GetComponent<RectTransform>();
                brt.anchorMin = new Vector2(1, 0.5f);
                brt.anchorMax = new Vector2(1, 0.5f);
                brt.pivot = new Vector2(1, 0.5f);
                brt.anchoredPosition = new Vector2(-15, 0);
                brt.sizeDelta = new Vector2(110, 44);
                var bimg = btnObj.GetComponent<Image>();
                bimg.sprite = cardSprite;
                bimg.type = Image.Type.Sliced;
                bimg.color = new Color(0.18f, 0.55f, 0.95f);

                var btxtObj = new GameObject("Label", typeof(RectTransform), typeof(Text));
                btxtObj.transform.SetParent(btnObj.transform, false);
                var btrt = btxtObj.GetComponent<RectTransform>();
                btrt.anchorMin = Vector2.zero;
                btrt.anchorMax = Vector2.one;
                btrt.offsetMin = Vector2.zero;
                btrt.offsetMax = Vector2.zero;
                var btxt = btxtObj.GetComponent<Text>();
                btxt.font = font;
                btxt.fontSize = 16;
                btxt.color = Color.white;
                btxt.alignment = TextAnchor.MiddleCenter;
                btxt.text = Strings.CurrentLanguage == "ru" ? "Выбрать" : (Strings.CurrentLanguage == "uz" ? "Tanlash" : "Select");

                btnObj.GetComponent<Button>().onClick.AddListener(() =>
                {
                    MapSelectPanel.SetActive(false);
                });
            }
        }
    }
}
