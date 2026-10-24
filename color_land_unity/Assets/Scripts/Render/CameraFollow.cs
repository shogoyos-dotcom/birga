using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// O'yinchini yuqoridan silliq kuzatib boruvchi kamera (Top-down Smooth Camera).
    /// </summary>
    public class CameraFollow : MonoBehaviour
    {
        public Transform Target;
        public Vector3 Offset = new Vector3(0, 32, -22);
        public float SmoothSpeed = 6.0f;

        private void LateUpdate()
        {
            if (Target == null) return;

            Vector3 desiredPosition = Target.position + Offset;
            Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, SmoothSpeed * Time.deltaTime);
            transform.position = smoothedPosition;
            transform.LookAt(Target.position + Vector3.forward * 4.0f);
        }
    }
}
