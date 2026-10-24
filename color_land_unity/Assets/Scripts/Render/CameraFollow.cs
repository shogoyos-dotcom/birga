using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// O'yinchini yuqoridan silliq kuzatib boruvchi kamera (Top-down Smooth Camera).
    /// Tasdiqlangan Color Land 3D portret (1080x1920) qiyofasiga to'liq mos keladi.
    /// </summary>
    public class CameraFollow : MonoBehaviour
    {
        public Transform Target;
        public Vector3 Offset = new Vector3(0, 22.0f, -15.5f);
        public Vector3 LookOffset = new Vector3(0, 0.8f, 2.5f);
        public float SmoothSpeed = 8.0f;

        private void LateUpdate()
        {
            if (Target == null) return;

            Vector3 desiredPosition = Target.position + Offset;
            transform.position = Vector3.Lerp(transform.position, desiredPosition, SmoothSpeed * Time.deltaTime);
            transform.LookAt(Target.position + LookOffset);
        }
    }
}
