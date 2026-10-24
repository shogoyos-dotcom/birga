using System;
using UnityEngine;

namespace ColorLand.Logic
{
    /// <summary>
    /// UnityEngine MonoBehaviour ko'prigi.
    /// Transform va vizualizatsiyani PlayerEntity mantiqiy modeli bilan bog'laydi.
    /// </summary>
    public class PlayerState : MonoBehaviour
    {
        public PlayerEntity Entity { get; private set; }

        public void Bind(PlayerEntity entity)
        {
            Entity = entity;
            transform.position = entity.Position;
        }

        private void Update()
        {
            if (Entity != null)
            {
                transform.position = Entity.Position;
                if (Entity.Forward.sqrMagnitude > 0.01f)
                {
                    transform.rotation = Quaternion.LookRotation(Entity.Forward, Vector3.up);
                }
                if (!Entity.IsAlive && gameObject.activeSelf)
                {
                    gameObject.SetActive(false);
                }
            }
        }
    }
}
