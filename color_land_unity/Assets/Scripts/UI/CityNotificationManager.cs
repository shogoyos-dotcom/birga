using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using ColorLand.Logic;
using ColorLand.App;

namespace ColorLand.UI
{
    /// <summary>
    /// Shahar egallash bildirishnomalari boshqaruvchisi (CityNotificationManager).
    /// Phase 8.4 TASK 5 talablariga 100% javob beradi:
    /// 1. Matnlarning bir-birining ustiga chiqib ketishini butunlay oldini oladi (Sequential Queue).
    /// 2. Mahalliy shahar nomi, sarlavha va mukofot ixcham, chiroyli bitta kartada ko'rsatiladi.
    /// 3. Bir xil shahar uchun takroriy bildirishnomalarni bloklaydi.
    /// 4. Joystik va asosiy HUD ga xalaqit bermaydi (ekranning yuqori xavfsiz qismida joylashadi).
    /// 5. 2.2 soniyadan so'ng silliq animatsiya bilan yo'qoladi.
    /// </summary>
    public class CityNotificationManager : MonoBehaviour
    {
        public static CityNotificationManager Instance { get; private set; }

        [Header("UI Components")]
        public RectTransform NotificationPanel;
        public CanvasGroup CanvasGroup;
        public Text TitleText;       // "ГОРОД ЗАХВАЧЕН!"
        public Text CityNameText;    // "ПОРТ-СУДАН"
        public Text RewardText;      // "+200 🪙"

        private readonly Queue<NotificationItem> _queue = new Queue<NotificationItem>();
        private readonly HashSet<int> _activeNoticeIds = new HashSet<int>();
        private bool _isShowing = false;

        private struct NotificationItem
        {
            public int CityId;
            public string LocalizedCityName;
            public int Reward;
        }

        private void Awake()
        {
            Instance = this;
            if (CanvasGroup != null)
            {
                CanvasGroup.alpha = 0f;
                CanvasGroup.blocksRaycasts = false;
            }
        }

        /// <summary>
        /// Yangi shahar egallanganda bildirishnomani navbatga qo'shish.
        /// </summary>
        public void NotifyCityCaptured(CityData city, int reward)
        {
            if (city == null) return;

            // Takroriy xabarlarni filtrlash
            if (_activeNoticeIds.Contains(city.Id)) return;
            _activeNoticeIds.Add(city.Id);

            _queue.Enqueue(new NotificationItem
            {
                CityId = city.Id,
                LocalizedCityName = city.LocalizedName.ToUpperInvariant(),
                Reward = reward
            });

            if (!_isShowing)
            {
                StartCoroutine(ProcessQueueCoroutine());
            }
        }

        private IEnumerator ProcessQueueCoroutine()
        {
            _isShowing = true;

            while (_queue.Count > 0)
            {
                var item = _queue.Dequeue();

                // Matnlarni markazlashtirilgan lokalizatsiya bilan to'ldirish
                if (TitleText != null)
                {
                    TitleText.text = Strings.T("cityCaptured").ToUpperInvariant();
                }
                if (CityNameText != null)
                {
                    CityNameText.text = item.LocalizedCityName;
                }
                if (RewardText != null)
                {
                    RewardText.text = $"+{item.Reward} 🪙";
                }

                // Silliq ko'rinish (Fade In) - 0.25 sek
                float elapsed = 0f;
                float fadeInDuration = 0.25f;
                while (elapsed < fadeInDuration)
                {
                    elapsed += Time.unscaledDeltaTime;
                    if (CanvasGroup != null)
                    {
                        CanvasGroup.alpha = Mathf.Clamp01(elapsed / fadeInDuration);
                    }
                    yield return null;
                }
                if (CanvasGroup != null) CanvasGroup.alpha = 1f;

                // Ekranda turish vaqti - 2.0 sek
                yield return new WaitForSecondsRealtime(2.0f);

                // Silliq yo'qolish (Fade Out) - 0.35 sek
                elapsed = 0f;
                float fadeOutDuration = 0.35f;
                while (elapsed < fadeOutDuration)
                {
                    elapsed += Time.unscaledDeltaTime;
                    if (CanvasGroup != null)
                    {
                        CanvasGroup.alpha = Mathf.Clamp01(1f - (elapsed / fadeOutDuration));
                    }
                    yield return null;
                }
                if (CanvasGroup != null) CanvasGroup.alpha = 0f;

                _activeNoticeIds.Remove(item.CityId);
                yield return new WaitForSecondsRealtime(0.1f);
            }

            _isShowing = false;
        }
    }
}
