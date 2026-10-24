using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.App;

namespace ColorLand.UI
{
    /// <summary>
    /// Til tanlash oynasi (LanguagePickerModal).
    /// Phase 8.4 TASK 2 talablariga to'liq javob beradi:
    /// - 15 ta qo'llab-quvvatlanuvchi tillarning to'liq ro'yxati (Native Name bilan).
    /// - Joriy faol tilni yaqqol ajratib ko'rsatish (Green Checkmark / highlight).
    /// - Bir marta bosish bilan darhol tilni o'zgartirish va saqlash (qayta yuklamasdan).
    /// - Portrait Android ekranlariga mos sensorli skrolling va yopish tugmasi.
    /// </summary>
    public class LanguagePickerModal : MonoBehaviour
    {
        public static LanguagePickerModal Instance { get; private set; }

        [Header("UI Containers")]
        public GameObject ModalRoot;
        public RectTransform ContentContainer;
        public Text HeaderTitle;
        public Button CloseButton;

        private readonly List<GameObject> _spawnedItems = new List<GameObject>();

        private void Awake()
        {
            Instance = this;
            if (CloseButton != null)
            {
                CloseButton.onClick.AddListener(Hide);
            }
            if (ModalRoot != null)
            {
                ModalRoot.SetActive(false);
            }
        }

        private void Start()
        {
            Strings.OnLanguageChanged += UpdateHeader;
            UpdateHeader();
        }

        private void OnDestroy()
        {
            Strings.OnLanguageChanged -= UpdateHeader;
        }

        private void UpdateHeader()
        {
            if (HeaderTitle != null)
            {
                HeaderTitle.text = Strings.T("selectLanguage");
            }
        }

        public void Show()
        {
            if (ModalRoot != null) ModalRoot.SetActive(true);
            UpdateHeader();
            PopulateLanguages();
        }

        public void Hide()
        {
            if (ModalRoot != null) ModalRoot.SetActive(false);
        }

        public void Toggle()
        {
            if (ModalRoot != null)
            {
                if (ModalRoot.activeSelf) Hide();
                else Show();
            }
        }

        private void PopulateLanguages()
        {
            foreach (var go in _spawnedItems)
            {
                if (go != null) Destroy(go);
            }
            _spawnedItems.Clear();

            if (ContentContainer == null) return;

            string currentLang = Strings.CurrentLanguage ?? "ru";

            foreach (var lang in Strings.SupportedLanguages)
            {
                bool isSelected = string.Equals(lang.Code, currentLang, System.StringComparison.OrdinalIgnoreCase);

                // Element tugmasi yaratish
                var itemObj = new GameObject($"Lang_{lang.Code}", typeof(RectTransform), typeof(Image), typeof(Button));
                itemObj.transform.SetParent(ContentContainer, false);
                _spawnedItems.Add(itemObj);

                var rt = itemObj.GetComponent<RectTransform>();
                rt.sizeDelta = new Vector2(0, 56);

                var img = itemObj.GetComponent<Image>();
                img.color = isSelected ? new Color(0.12f, 0.45f, 0.85f, 0.95f) : new Color(0.18f, 0.22f, 0.28f, 0.90f);

                var btn = itemObj.GetComponent<Button>();
                string langCode = lang.Code;
                btn.onClick.AddListener(() =>
                {
                    OnLanguageSelected(langCode);
                });

                // Matn: Masalan: "Русский (ru)" yoki "O'zbekcha (uz)" + " ✓"
                var textObj = new GameObject("Label", typeof(RectTransform), typeof(Text));
                textObj.transform.SetParent(itemObj.transform, false);

                var textRt = textObj.GetComponent<RectTransform>();
                textRt.anchorMin = Vector2.zero;
                textRt.anchorMax = Vector2.one;
                textRt.offsetMin = new Vector2(20, 0);
                textRt.offsetMax = new Vector2(-20, 0);

                var lbl = textObj.GetComponent<Text>();
                lbl.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf") ?? Resources.GetBuiltinResource<Font>("Arial.ttf");
                lbl.fontSize = 20;
                lbl.fontStyle = isSelected ? FontStyle.Bold : FontStyle.Normal;
                lbl.color = isSelected ? Color.yellow : Color.white;
                lbl.alignment = TextAnchor.MiddleLeft;

                string checkmark = isSelected ? "  ✓" : "";
                lbl.text = $"{lang.NativeName} ({lang.Code.ToUpperInvariant()}){checkmark}";
            }
        }

        private void OnLanguageSelected(string code)
        {
            Strings.SetLanguage(code);
            // Ro'yxatni yangilash
            PopulateLanguages();
        }
    }
}
