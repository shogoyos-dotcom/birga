using System;
using System.Collections.Generic;
using UnityEngine;
using ColorLand.Render;
using ColorLand.App;

namespace ColorLand.Logic
{
    /// <summary>
    /// O'yin dunyosi boshqaruvchisi (GameWorld).
    /// Grid, Player, 20 ta Bot, PaintLayer, shaharlar va kamerani sinxron boshqaradi.
    /// Multfilm 3D vizual qahramonlar, bayroqlar va palitrani GPU bilan bog'laydi.
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

        private static readonly string[] BotCountryCodes = new string[]
        {
            "RU", "KZ", "TR", "DE", "FR", "JP", "US", "BR", "CN", "GB",
            "IT", "ES", "IN", "KR", "EG", "SA", "AE", "CA", "AU", "ZA"
        };

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

            if (PaintLayer != null)
            {
                PaintLayer.SetPaletteColor(Player.OwnerId, Player.PlayerColor);
            }

            Player.OnTerritoryCaptured += (count) =>
            {
                if (PaintLayer != null) PaintLayer.UpdateFull();
            };

            Player.OnDied += (p) =>
            {
                ClearOwnerCells(p.OwnerId);
                if (p.LastAttackerId > 1)
                {
                    var attacker = Bots.Find(b => b.OwnerId == p.LastAttackerId);
                    if (attacker != null) attacker.Kills++;
                }
            };

            GameObject playerObj = PlayerPrefab != null ? Instantiate(PlayerPrefab) : CreateDefaultCharacterObject("Player", Player.PlayerColor, "UZ");
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

            Color[] presetColors = new Color[]
            {
                new Color(0.96f, 0.26f, 0.21f), // Qizil
                new Color(1.00f, 0.60f, 0.00f), // Sabzirang
                new Color(1.00f, 0.85f, 0.00f), // Sariq
                new Color(0.61f, 0.15f, 0.69f), // Binafsha
                new Color(0.91f, 0.12f, 0.39f), // Pushti
                new Color(0.00f, 0.75f, 0.65f), // Teal
                new Color(0.20f, 0.80f, 0.20f), // Yashil
                new Color(0.40f, 0.20f, 0.60f), // To'q binafsha
                new Color(1.00f, 0.40f, 0.60f), // Och pushti
                new Color(0.10f, 0.85f, 0.90f), // Moviy
                new Color(0.85f, 0.65f, 0.13f), // Oltin
                new Color(0.70f, 0.30f, 0.10f), // Jigarrang
                new Color(0.10f, 0.50f, 0.80f), // Kobalt
                new Color(0.80f, 0.10f, 0.50f), // Fuksia
                new Color(0.30f, 0.70f, 0.90f), // Havorang
                new Color(0.60f, 0.80f, 0.20f), // Laym
                new Color(0.95f, 0.50f, 0.30f), // Shaftoli
                new Color(0.50f, 0.50f, 0.90f), // Nilrang
                new Color(0.90f, 0.20f, 0.40f), // Malina
                new Color(0.15f, 0.75f, 0.45f), // Zumrad
            };

            for (int i = 0; i < BotCount; i++)
            {
                byte botId = (byte)(i + 2);
                Vector2Int botSpawn = FindSafeSpawn(rnd);

                Color botColor = (i < presetColors.Length) ? presetColors[i] : UnityEngine.Random.ColorHSV(0f, 1f, 0.6f, 0.9f, 0.7f, 1.0f);
                string bCountry = (i < BotCountryCodes.Length) ? BotCountryCodes[i] : "UN";

                var botEntity = new PlayerEntity(Grid, CaptureSystem, botSpawn, botId)
                {
                    PlayerName = $"Bot_{i + 1}",
                    CountryCode = bCountry,
                    PlayerColor = botColor
                };

                if (PaintLayer != null)
                {
                    PaintLayer.SetPaletteColor(botId, botColor);
                }

                botEntity.OnTerritoryCaptured += (count) =>
                {
                    if (PaintLayer != null) PaintLayer.UpdateFull();
                };

                botEntity.OnDied += (b) =>
                {
                    ClearOwnerCells(b.OwnerId);
                    if (b.LastAttackerId == Player.OwnerId)
                    {
                        Player.Kills++;
                    }
                    else if (b.LastAttackerId > 1)
                    {
                        var attacker = Bots.Find(a => a.OwnerId == b.LastAttackerId);
                        if (attacker != null) attacker.Kills++;
                    }
                };

                GameObject botObj = BotPrefab != null ? Instantiate(BotPrefab) : CreateDefaultCharacterObject($"Bot_{botId}", botColor, bCountry);
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

        private GameObject CreateDefaultCharacterObject(string name, Color color, string countryCode)
        {
            var root = new GameObject(name);

            Shader litShader = Shader.Find("ColorLand/CartoonLit")
                            ?? Shader.Find("Universal Render Pipeline/Lit")
                            ?? Shader.Find("Standard")
                            ?? Shader.Find("Mobile/Diffuse");

            // 1. Tana (Yumaloq kapsula)
            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            body.name = "Body";
            body.transform.SetParent(root.transform, false);
            body.transform.localPosition = new Vector3(0, 0.45f, 0);
            body.transform.localScale = new Vector3(0.85f, 0.45f, 0.85f);

            var bodyMat = new Material(litShader)
            {
                color = color,
                name = $"M_Body_{name}"
            };
            body.GetComponent<Renderer>().sharedMaterial = bodyMat;
            var bodyCol = body.GetComponent<Collider>();
            if (bodyCol != null) Destroy(bodyCol);

            // 2. Ko'zlar (Ikkita oq shar + qora qorachiqlar)
            var eyeMat = new Material(litShader) { color = Color.white, name = "M_EyeWhite" };
            var pupilMat = new Material(litShader) { color = new Color(0.1f, 0.1f, 0.15f), name = "M_PupilDark" };

            for (int eyeIdx = -1; eyeIdx <= 1; eyeIdx += 2)
            {
                var eye = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                eye.name = $"Eye_{eyeIdx}";
                eye.transform.SetParent(root.transform, false);
                eye.transform.localPosition = new Vector3(eyeIdx * 0.22f, 0.55f, 0.35f);
                eye.transform.localScale = new Vector3(0.18f, 0.22f, 0.16f);
                eye.GetComponent<Renderer>().sharedMaterial = eyeMat;
                var eCol = eye.GetComponent<Collider>();
                if (eCol != null) Destroy(eCol);

                var pupil = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                pupil.name = "Pupil";
                pupil.transform.SetParent(eye.transform, false);
                pupil.transform.localPosition = new Vector3(0, 0, 0.45f);
                pupil.transform.localScale = new Vector3(0.55f, 0.55f, 0.45f);
                pupil.GetComponent<Renderer>().sharedMaterial = pupilMat;
                var pCol = pupil.GetComponent<Collider>();
                if (pCol != null) Destroy(pCol);
            }

            // 3. Yo'nalish ko'rsatkichi / Burun (Vizor)
            var visor = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            visor.name = "Visor";
            visor.transform.SetParent(root.transform, false);
            visor.transform.localPosition = new Vector3(0, 0.42f, 0.42f);
            visor.transform.localRotation = Quaternion.Euler(90f, 0, 0);
            visor.transform.localScale = new Vector3(0.14f, 0.08f, 0.14f);
            var visorMat = new Material(litShader) { color = new Color(1.0f, 0.88f, 0.25f), name = "M_Visor" };
            visor.GetComponent<Renderer>().sharedMaterial = visorMat;
            var vCol = visor.GetComponent<Collider>();
            if (vCol != null) Destroy(vCol);

            // 4. Bayroq ustuni (Orqada silindr)
            var pole = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            pole.name = "Pole";
            pole.transform.SetParent(root.transform, false);
            pole.transform.localPosition = new Vector3(0, 0.90f, -0.32f);
            pole.transform.localScale = new Vector3(0.04f, 0.45f, 0.04f);
            var poleMat = new Material(litShader) { color = new Color(0.85f, 0.85f, 0.90f), name = "M_Pole" };
            pole.GetComponent<Renderer>().sharedMaterial = poleMat;
            var polCol = pole.GetComponent<Collider>();
            if (polCol != null) Destroy(polCol);

            // 5. Bayroq matosi (Quad)
            var flag = GameObject.CreatePrimitive(PrimitiveType.Quad);
            flag.name = "Flag";
            flag.transform.SetParent(root.transform, false);
            flag.transform.localPosition = new Vector3(0.25f, 1.15f, -0.32f);
            flag.transform.localRotation = Quaternion.Euler(0, 90f, 0);
            flag.transform.localScale = new Vector3(0.50f, 0.32f, 1.0f);

            // Bayroq rasmini yuklash
            Sprite flagSprite = Resources.Load<Sprite>($"Flags/png/{countryCode.ToUpperInvariant()}");
            var flagMat = new Material(litShader) { name = $"M_Flag_{countryCode}" };
            if (flagSprite != null)
            {
                flagMat.mainTexture = flagSprite.texture;
                flagMat.color = Color.white;
            }
            else
            {
                flagMat.color = color;
            }
            flag.GetComponent<Renderer>().sharedMaterial = flagMat;
            var fCol = flag.GetComponent<Collider>();
            if (fCol != null) Destroy(fCol);

            // 6. Trigger kollayder
            var rootCol = root.AddComponent<CapsuleCollider>();
            rootCol.center = new Vector3(0, 0.45f, 0);
            rootCol.radius = 0.45f;
            rootCol.height = 0.9f;
            rootCol.isTrigger = true;

            return root;
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

                Player.UpdateDanger(Time.deltaTime);
            }

            foreach (var bot in Bots)
            {
                if (bot != null && bot.IsAlive)
                {
                    bot.UpdateDanger(Time.deltaTime);
                }
            }

            CheckCollisions();
        }

        private void CheckCollisions()
        {
            if (Player != null && Player.IsAlive)
            {
                Vector2Int playerHead = Grid.WorldToGrid(Player.Position);

                foreach (var bot in Bots)
                {
                    if (!bot.IsAlive) continue;

                    // O'yinchi botning iziga tegsa -> xavf to'lqini boshlanadi
                    if (bot.CheckTrailCollision(playerHead))
                    {
                        bot.TriggerTrailDanger(Player.OwnerId, playerHead);
                    }

                    // Bot o'yinchining iziga tegsa -> xavf to'lqini boshlanadi
                    Vector2Int botHead = Grid.WorldToGrid(bot.Position);
                    if (Player.CheckTrailCollision(botHead))
                    {
                        Player.TriggerTrailDanger(bot.OwnerId, botHead);
                    }

                    // Boshlar to'qnashuvi
                    if (playerHead == botHead)
                    {
                        Player.Die();
                        bot.Die();
                    }
                }
            }

            // Botlar o'zaro bir-birining izini kesishi
            for (int i = 0; i < Bots.Count; i++)
            {
                var botA = Bots[i];
                if (!botA.IsAlive) continue;
                Vector2Int headA = Grid.WorldToGrid(botA.Position);

                for (int j = 0; j < Bots.Count; j++)
                {
                    if (i == j) continue;
                    var botB = Bots[j];
                    if (!botB.IsAlive) continue;

                    if (botB.CheckTrailCollision(headA))
                    {
                        botB.TriggerTrailDanger(botA.OwnerId, headA);
                    }
                }
            }
        }

        public void ClearOwnerCells(byte ownerId)
        {
            int total = Grid.Width * Grid.Height;
            for (int y = 0; y < Grid.Height; y++)
            {
                for (int x = 0; x < Grid.Width; x++)
                {
                    if (Grid.GetOwner(x, y) == ownerId)
                    {
                        Grid.SetOwner(x, y, GameGrid.OWNER_NONE);
                        if (PaintLayer != null)
                        {
                            PaintLayer.SetCell(x, y, GameGrid.OWNER_NONE);
                        }
                    }
                }
            }
            if (PaintLayer != null) PaintLayer.UpdateFull();
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
