using System;
using System.Collections.Generic;
using UnityEngine;
using ColorLand.Render;
using ColorLand.App;

namespace ColorLand.Logic
{
    /// <summary>
    /// O'yin dunyosi boshqaruvchisi (GameWorld).
    /// </summary>
    public class GameWorld : MonoBehaviour
    {
        public static GameWorld Instance { get; private set; }

        [Header("Settings")]
        public int GridWidth = 120;
        public int GridHeight = 120;
        public float CellSize = 1.0f;
        public int BotCount = 20;

        [Header("Prefabs & References")]
        public GameObject PlayerPrefab;
        public GameObject BotPrefab;
        public PaintLayer PaintLayer;
        public Material ArenaMaterial;
        public CityRenderer CityRenderer;

        public GameGrid Grid { get; private set; }
        public TerritoryCapture CaptureSystem { get; private set; }
        public CitySystem CitySystem { get; private set; }
        public PlayerEntity Player { get; private set; }
        public List<PlayerEntity> Bots { get; private set; } = new List<PlayerEntity>();

        private void Awake()
        {
            Instance = this;
        }

        private void Start()
        {
            InitializeGame();
        }

        public void InitializeGame()
        {
            Grid = new GameGrid(GridWidth, GridHeight, CellSize);
            CitySystem = new CitySystem(Grid);
            CitySystem.LoadDefaultCities(GridWidth, GridHeight);
            CaptureSystem = new TerritoryCapture(Grid, CitySystem);

            if (CityRenderer != null)
            {
                CityRenderer.Initialize(CitySystem);
            }

            CitySystem.OnCityCaptured += (city, capturerId, reward) =>
            {
                if (capturerId == 1)
                {
                    if (ColorLand.UI.CityNotificationManager.Instance != null)
                    {
                        ColorLand.UI.CityNotificationManager.Instance.NotifyCityCaptured(city, reward);
                    }
                }
            };

            if (PaintLayer != null)
            {
                PaintLayer.Initialize(Grid, ArenaMaterial);
            }

            // 1. O'yinchi
            Vector2Int playerSpawn = new Vector2Int(GridWidth / 2, GridHeight / 2);
            Player = new PlayerEntity(Grid, CaptureSystem, playerSpawn, 1)
            {
                PlayerName = "SHO",
                CountryCode = "UZ",
                PlayerColor = new Color(0.15f, 0.65f, 1.0f)
            };

            Player.OnTerritoryCaptured += (count) =>
            {
                if (PaintLayer != null) PaintLayer.UpdateFull();
            };

            GameObject playerObj = PlayerPrefab != null ? Instantiate(PlayerPrefab) : CreateDefaultCharacterObject("Player", Player.PlayerColor);
            var playerState = playerObj.GetComponent<PlayerState>() ?? playerObj.AddComponent<PlayerState>();
            playerState.Bind(Player);

            var playerRibbon = playerObj.GetComponent<TrailRibbon>() ?? playerObj.AddComponent<TrailRibbon>();
            playerRibbon.State = playerState;
            playerRibbon.Initialize(Grid, Player.PlayerColor);

            // Kamera kuzatuvi
            var cam = Camera.main;
            if (cam != null)
            {
                var follow = cam.GetComponent<CameraFollow>() ?? cam.gameObject.AddComponent<CameraFollow>();
                follow.Target = playerObj.transform;
            }

            // 2. 20 ta Bot
            Bots.Clear();
            System.Random rnd = new System.Random(12345);

            for (int i = 0; i < BotCount; i++)
            {
                byte botId = (byte)(i + 2);
                Vector2Int botSpawn = FindSafeSpawn(rnd);

                Color botColor = UnityEngine.Random.ColorHSV(0f, 1f, 0.6f, 0.9f, 0.7f, 1.0f);
                var botEntity = new PlayerEntity(Grid, CaptureSystem, botSpawn, botId)
                {
                    PlayerName = $"Bot_{i + 1}",
                    PlayerColor = botColor
                };

                botEntity.OnTerritoryCaptured += (count) =>
                {
                    if (PaintLayer != null) PaintLayer.UpdateFull();
                };

                GameObject botObj = BotPrefab != null ? Instantiate(BotPrefab) : CreateDefaultCharacterObject($"Bot_{botId}", botColor);
                var botState = botObj.GetComponent<PlayerState>() ?? botObj.AddComponent<PlayerState>();
                botState.Bind(botEntity);

                var botRibbon = botObj.GetComponent<TrailRibbon>() ?? botObj.AddComponent<TrailRibbon>();
                botRibbon.State = botState;
                botRibbon.Initialize(Grid, botColor);

                var botAI = botObj.GetComponent<BotAI>() ?? botObj.AddComponent<BotAI>();
                botAI.State = botState;
                botAI.Initialize(Grid, i * 77 + 13);

                Bots.Add(botEntity);
            }

            if (PaintLayer != null)
            {
                PaintLayer.UpdateFull();
            }
        }

        private GameObject CreateDefaultCharacterObject(string name, Color color)
        {
            var go = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            go.name = name;
            go.transform.localScale = new Vector3(0.8f, 0.5f, 0.8f);

            var rend = go.GetComponent<Renderer>();
            if (rend != null)
            {
                var mat = new Material(Shader.Find("Universal Render Pipeline/Lit") ?? Shader.Find("Standard"))
                {
                    color = color
                };
                rend.material = mat;
            }

            // Colliderni trigger qilamiz (fizika xalaqit bermasligi uchun)
            var col = go.GetComponent<Collider>();
            if (col != null) col.isTrigger = true;

            return go;
        }

        private Vector2Int FindSafeSpawn(System.Random rnd)
        {
            for (int attempts = 0; attempts < 100; attempts++)
            {
                int x = rnd.Next(10, GridWidth - 10);
                int y = rnd.Next(10, GridHeight - 10);

                if (Grid.IsLand(x, y) && Grid.GetOwner(x, y) == GameGrid.OWNER_NONE)
                {
                    return new Vector2Int(x, y);
                }
            }
            return new Vector2Int(GridWidth / 2, GridHeight / 2);
        }

        private void Update()
        {
            if (Player != null && Player.IsAlive)
            {
                Vector2 inputDir = ColorLand.UI.VirtualJoystick.Instance != null 
                    ? ColorLand.UI.VirtualJoystick.Instance.GetMovementVector() 
                    : new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));

                if (inputDir.sqrMagnitude > 0.01f)
                {
                    Player.Move(inputDir, Time.deltaTime);
                }
            }

            CheckCollisions();
        }

        private void CheckCollisions()
        {
            if (Player == null || !Player.IsAlive) return;

            Vector2Int playerHead = Grid.WorldToGrid(Player.Position);

            foreach (var bot in Bots)
            {
                if (!bot.IsAlive) continue;

                if (bot.CheckTrailCollision(playerHead))
                {
                    bot.Die();
                    Player.Kills++;
                    ClearOwnerCells(bot.OwnerId);
                }

                Vector2Int botHead = Grid.WorldToGrid(bot.Position);
                if (Player.CheckTrailCollision(botHead))
                {
                    Player.Die();
                    bot.Kills++;
                    ClearOwnerCells(Player.OwnerId);
                    break;
                }
            }
        }

        public void ClearOwnerCells(byte ownerId)
        {
            for (int y = 0; y < Grid.Height; y++)
            {
                for (int x = 0; x < Grid.Width; x++)
                {
                    if (Grid.GetOwner(x, y) == ownerId)
                    {
                        Grid.SetOwner(x, y, GameGrid.OWNER_NONE);
                    }
                }
            }
            if (PaintLayer != null)
            {
                PaintLayer.UpdateFull();
            }
        }

        public float GetPlayerTerritoryPercentage()
        {
            if (Grid == null || Player == null) return 0f;
            int totalLand = Grid.TotalLandCells();
            if (totalLand == 0) return 0f;
            return (float)Grid.CountOwnedCells(Player.OwnerId) / totalLand * 100f;
        }
    }
}
