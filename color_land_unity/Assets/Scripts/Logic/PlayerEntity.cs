using System;
using System.Collections.Generic;
using UnityEngine;

namespace ColorLand.Logic
{
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

        public Vector3 Position { get; set; }
        public Vector3 Forward { get; set; } = Vector3.forward;

        public readonly List<Vector2Int> Trail = new List<Vector2Int>();
        private Vector2Int _currentGridPos;
        private readonly GameGrid _grid;
        private readonly TerritoryCapture _capture;

        public event Action<PlayerEntity> OnDied;
        public event Action<int> OnTerritoryCaptured;

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
                    Die();
                    return;
                }
                Trail.Add(newCell);
            }
        }

        public void Die()
        {
            if (!IsAlive) return;
            IsAlive = false;
            Trail.Clear();
            OnDied?.Invoke(this);
        }

        public bool CheckTrailCollision(Vector2Int headPos)
        {
            return Trail.Contains(headPos);
        }
    }
}
