using UnityEngine;
using UnityEngine.EventSystems;
using UnityEngine.UI;

namespace ColorLand.UI
{
    /// <summary>
    /// Mobil qurilmalar uchun virtual joystik (VirtualJoystick).
    /// Sensorli ekranlarda teginish va sudrab boshqarishni,
    /// kompyuterda esa sichqoncha hamda WASD/strelkalar bilan boshqarishni ta'minlaydi.
    /// </summary>
    public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
    {
        public static VirtualJoystick Instance { get; private set; }

        [Header("UI Elements")]
        public RectTransform Background;
        public RectTransform Handle;

        [Header("Settings")]
        public float HandleRange = 60f;

        public Vector2 InputDirection { get; private set; } = Vector2.zero;

        private Vector2 _startPosition;

        private void Awake()
        {
            Instance = this;
            if (Background != null)
            {
                _startPosition = Background.anchoredPosition;
            }
        }

        public void OnPointerDown(PointerEventData eventData)
        {
            OnDrag(eventData);
        }

        public void OnDrag(PointerEventData eventData)
        {
            if (Background == null || Handle == null) return;

            RectTransformUtility.ScreenPointToLocalPointInRectangle(
                Background,
                eventData.position,
                eventData.pressEventCamera,
                out Vector2 position
            );

            position = Vector2.ClampMagnitude(position, HandleRange);
            Handle.anchoredPosition = position;
            InputDirection = position / HandleRange;
        }

        public void OnPointerUp(PointerEventData eventData)
        {
            InputDirection = Vector2.zero;
            if (Handle != null)
            {
                Handle.anchoredPosition = Vector2.zero;
            }
        }

        /// <summary>
        /// Sensorli yoki klaviatura orqali yakuniy yo'nalish vektori.
        /// </summary>
        public Vector2 GetMovementVector()
        {
            if (InputDirection.sqrMagnitude > 0.01f)
            {
                return InputDirection;
            }

            float h = Input.GetAxisRaw("Horizontal");
            float v = Input.GetAxisRaw("Vertical");
            Vector2 keyboardDir = new Vector2(h, v);
            if (keyboardDir.sqrMagnitude > 0.01f)
            {
                return keyboardDir.normalized;
            }

            return Vector2.zero;
        }
    }
}
