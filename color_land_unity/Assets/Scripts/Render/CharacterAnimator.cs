using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Qahramon va botlar uchun silliq multfilm animatori (CharacterAnimator).
    /// Harakatlanayotganda nafas olish (breathing), qadam bosish (squash & stretch bobbing)
    /// va orqadagi bayroqning shamolda hilpirashini ta'minlaydi.
    /// </summary>
    public class CharacterAnimator : MonoBehaviour
    {
        public Transform Body;
        public Transform Flag;
        public float WalkBobSpeed = 12.0f;
        public float WalkBobAmount = 0.12f;
        public float FlagWaveSpeed = 6.0f;
        public float FlagWaveAmount = 8.0f;

        private Vector3 _lastPos;
        private Vector3 _bodyBaseScale = Vector3.one;
        private Vector3 _bodyBasePos = Vector3.zero;
        private Quaternion _flagBaseRot = Quaternion.identity;
        private float _speed = 0.0f;

        private void Start()
        {
            _lastPos = transform.position;
            if (Body != null)
            {
                _bodyBaseScale = Body.localScale;
                _bodyBasePos = Body.localPosition;
            }
            if (Flag != null)
            {
                _flagBaseRot = Flag.localRotation;
            }
        }

        private void Update()
        {
            float dt = Time.deltaTime;
            if (dt <= 0.0001f) return;

            Vector3 curPos = transform.position;
            float movedDist = (curPos - _lastPos).magnitude;
            _lastPos = curPos;

            float curSpeed = movedDist / dt;
            _speed = Mathf.Lerp(_speed, curSpeed, dt * 8.0f);

            float t = Time.time;

            if (Body != null)
            {
                if (_speed > 0.5f)
                {
                    // Yurish animatsiyasi (Squash and stretch)
                    float bob = Mathf.Sin(t * WalkBobSpeed) * WalkBobAmount;
                    Body.localScale = new Vector3(
                        _bodyBaseScale.x * (1.0f - bob * 0.4f),
                        _bodyBaseScale.y * (1.0f + bob),
                        _bodyBaseScale.z * (1.0f - bob * 0.4f)
                    );
                    Body.localPosition = _bodyBasePos + new Vector3(0, Mathf.Abs(bob) * 0.15f, 0);
                }
                else
                {
                    // Tinch turganda mayin nafas olish (Idle breathing)
                    float breathe = Mathf.Sin(t * 3.0f) * 0.035f;
                    Body.localScale = new Vector3(
                        _bodyBaseScale.x * (1.0f - breathe * 0.5f),
                        _bodyBaseScale.y * (1.0f + breathe),
                        _bodyBaseScale.z * (1.0f - breathe * 0.5f)
                    );
                    Body.localPosition = _bodyBasePos;
                }
            }

            // Bayroqning shamolda hilpirashi
            if (Flag != null)
            {
                float wave = Mathf.Sin(t * FlagWaveSpeed) * FlagWaveAmount;
                Flag.localRotation = _flagBaseRot * Quaternion.Euler(0, wave, 0);
            }
        }
    }
}
