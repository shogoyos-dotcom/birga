using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.Logic
{
    public class TrailDanger
    {
        public byte AttackerId;
        public int CurrentTrailIndex;
        public float Timer;
        public float Speed = 30.0f; // katak/sekund
    }

    /// <summary>
    /// O'yinchi va botlarning sof mantiqiy modeli (Pure C# Domain Model).
    /// UnityEngine ning C++ dvigateliga qaram emas, shuning uchun 100% unit-test qilinadi.
    /// </summary>
    public class PlayerEntity
    {
        public byte OwnerId { get; set; } = 1;
        public string PlayerName { get; set; } = "Player";
        public string CountryCode { get; set; } = "UZ";
        public Color PlayerColor { get; set; } = new Color(0.2f, 0.7f, 1.0f);

        public float BaseSpeed { get; set; } = 5.0f;
        public float BoostSpeed { get; set; } = 8.0f;
        public bool IsBoosting { get; set; } = false;

        public bool IsAlive { get; private set; } = true;
        public int Kills { get; set; } = 0;
        public int CapturedCells { get; set; } = 0;
        public byte LastAttackerId { get; set; } = 0;

        public Vector3 Position { get; set; }
        public Vector3 Forward { get; set; } = Vector3.forward;

        public readonly List<Vector2Int> Trail = new List<Vector2Int>();
        public TrailDanger Danger { get; private set; }

        private Vector2Int _currentGridPos;
        private readonly GameGrid _grid;
        private readonly TerritoryCapture _capture;

        public event Action<PlayerEntity> OnDied;
        public event Action<int> OnTerritoryCaptured;
        public event Action<PlayerEntity, byte> OnDangerStarted;
        public event Action<PlayerEntity> OnDangerEscaped;

        public PlayerEntity(GameGrid grid, TerritoryCapture capture, Vector2Int startPos, byte ownerId = 1)
        {
            _grid = grid;
            _capture = capture;
            OwnerId = ownerId;
            _currentGridPos = startPos;
            Position = _grid.GridToWorld(startPos.x, startPos.y, 0.5f);
            IsAlive = true;
            Trail.Clear();

            _capture.SpawnInitialTerritory(OwnerId, startPos, 2);
        }

        public void Move(Vector2 inputDirection, float deltaTime)
        {
            if (!IsAlive || inputDirection.sqrMagnitude < 0.01f) return;

            Vector3 moveDir = new Vector3(inputDirection.x, 0, inputDirection.y).normalized;
            float currentSpeed = IsBoosting ? BoostSpeed : BaseSpeed;
            Vector3 targetVelocity = moveDir * currentSpeed;

            // Qirg'oq bo'ylab silliq siljish (Coastline sliding)
            Vector3 targetPos = Position + targetVelocity * deltaTime;
            Vector2Int targetGrid = _grid.WorldToGrid(targetPos);

            if (!_grid.IsLand(targetGrid.x, targetGrid.y))
            {
                Vector3 posX = Position + new Vector3(targetVelocity.x, 0, 0) * deltaTime;
                Vector2Int gridX = _grid.WorldToGrid(posX);

                Vector3 posZ = Position + new Vector3(0, 0, targetVelocity.z) * deltaTime;
                Vector2Int gridZ = _grid.WorldToGrid(posZ);

                if (_grid.IsLand(gridX.x, gridX.y))
                {
                    targetPos = posX;
                }
                else if (_grid.IsLand(gridZ.x, gridZ.y))
                {
                    targetPos = posZ;
                }
                else
                {
                    targetPos = Position;
                }
            }

            Position = targetPos;
            if (targetVelocity.sqrMagnitude > 0.01f)
            {
                Forward = targetVelocity.normalized;
            }

            Vector2Int newGridPos = _grid.WorldToGrid(Position);
            if (newGridPos != _currentGridPos)
            {
                OnEnterGridCell(newGridPos);
            }
        }

        private void OnEnterGridCell(Vector2Int newCell)
        {
            _currentGridPos = newCell;
            byte cellOwner = _grid.GetOwner(newCell.x, newCell.y);

            if (cellOwner == OwnerId)
            {
                if (Trail.Count > 0)
                {
                    bool wasInDanger = (Danger != null);
                    Danger = null; // Xavfdan o'z hududiga kirib qutuldi!
                    if (wasInDanger)
                    {
                        OnDangerEscaped?.Invoke(this);
                    }

                    int captured = _capture.ExecuteCapture(OwnerId, Trail);
                    CapturedCells += captured;
                    Trail.Clear();
                    OnTerritoryCaptured?.Invoke(captured);
                }
            }
            else
            {
                if (Trail.Contains(newCell))
                {
                    // Agar to'g'ridan-to'g'ri o'z izi bo'ylab ortga qaytayotgan bo'lsa (retrace)
                    if (Trail.Count >= 2 && newCell == Trail[Trail.Count - 2])
                    {
                        Trail.RemoveAt(Trail.Count - 1);
                        return;
                    }

                    Die();
                    return;
                }
                Trail.Add(newCell);
            }
        }

        public void TriggerTrailDanger(byte attackerId, Vector2Int hitCell)
        {
            if (!IsAlive || Trail.Count == 0) return;
            int hitIndex = Trail.IndexOf(hitCell);
            if (hitIndex < 0) return;

            // Agar bosh qismiga urilsa, darhol o'ladi
            if (hitIndex >= Trail.Count - 1)
            {
                LastAttackerId = attackerId;
                Die();
                return;
            }

            // Xavf to'lqini (danger wave) iz bo'ylab egasiga qarab yuguradi
            if (Danger == null || hitIndex > Danger.CurrentTrailIndex)
            {
                Danger = new TrailDanger
                {
                    AttackerId = attackerId,
                    CurrentTrailIndex = hitIndex,
                    Timer = 0f,
                    Speed = 30.0f
                };
                LastAttackerId = attackerId;
                OnDangerStarted?.Invoke(this, attackerId);
            }
        }

        public void UpdateDanger(float deltaTime)
        {
            if (!IsAlive || Danger == null || Trail.Count == 0) return;

            Danger.Timer += deltaTime * Danger.Speed;
            while (Danger.Timer >= 1.0f)
            {
                Danger.Timer -= 1.0f;
                Danger.CurrentTrailIndex++;

                if (Danger.CurrentTrailIndex >= Trail.Count)
                {
                    // Xavf to'lqini o'yinchiga yetib keldi — o'lim!
                    Die();
                    return;
                }
            }
        }

        public void Die()
        {
            if (!IsAlive) return;
            IsAlive = false;
            Danger = null;
            Trail.Clear();
            OnDied?.Invoke(this);
        }

        public bool CheckTrailCollision(Vector2Int headPos)
        {
            return Trail.Contains(headPos);
        }
    }
}
