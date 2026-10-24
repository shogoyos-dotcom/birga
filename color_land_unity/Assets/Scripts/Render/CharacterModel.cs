using UnityEngine;

namespace ColorLand.Render
{
    /// <summary>
    /// Color Land 3D — Kulgichli va Yaltiroq Multfilm Qahramon Modeli.
    /// Foydalanuvchi yuborgan rasmdagi ("Silliq harakat, chiroyli viz") yoqimli,
    /// katta ko'zli, tabassumli va yaltiroq multfilm shariga 100% mos keladi.
    /// </summary>
    public static class CharacterModel
    {
        public static GameObject BuildCuteCartoonBall(string name, Color bodyColor, string countryCode)
        {
            var root = new GameObject(name);

            Shader litShader = Shader.Find("ColorLand/CartoonLit")
                            ?? Shader.Find("Universal Render Pipeline/Lit")
                            ?? Shader.Find("Standard")
                            ?? Shader.Find("Mobile/Diffuse");

            // 0. Contact Shadow Disc (Yerdagi yumshoq aloqa soyasi)
            var shadow = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            shadow.name = "ContactShadow";
            shadow.transform.SetParent(root.transform, false);
            shadow.transform.localPosition = new Vector3(0, 0.02f, 0);
            shadow.transform.localScale = new Vector3(1.7f, 0.003f, 1.7f);
            var shadowMat = new Material(litShader)
            {
                color = new Color(0.04f, 0.08f, 0.14f, 0.45f),
                name = "M_ContactShadow"
            };
            shadow.GetComponent<Renderer>().sharedMaterial = shadowMat;
            var sCol = shadow.GetComponent<Collider>();
            if (sCol != null) UnityEngine.Object.DestroyImmediate(sCol);

            // 1. Asosiy Yaltiroq Tana Shari (Glossy Sphere)
            var body = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            body.name = "Body";
            body.transform.SetParent(root.transform, false);
            body.transform.localPosition = new Vector3(0, 0.85f, 0);
            body.transform.localScale = new Vector3(1.55f, 1.50f, 1.55f);

            var bodyMat = new Material(litShader)
            {
                color = bodyColor,
                name = $"M_Body_{name}"
            };
            body.GetComponent<Renderer>().sharedMaterial = bodyMat;
            var bCol = body.GetComponent<Collider>();
            if (bCol != null) UnityEngine.Object.DestroyImmediate(bCol);

            // 2. Katta va Yoqimli Multfilm Ko'zlari (Big Anime/Cartoon Eyes)
            var eyeBlackMat = new Material(litShader) { color = new Color(0.05f, 0.05f, 0.08f), name = "M_EyeBlack" };
            var glintMat = new Material(litShader) { color = Color.white, name = "M_EyeGlint" };

            for (int eyeIdx = -1; eyeIdx <= 1; eyeIdx += 2)
            {
                // Qora ko'z doirasi
                var eyeObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                eyeObj.name = $"Eye_{(eyeIdx < 0 ? "L" : "R")}";
                eyeObj.transform.SetParent(body.transform, false);
                eyeObj.transform.localPosition = new Vector3(eyeIdx * 0.24f, 0.12f, 0.40f);
                eyeObj.transform.localScale = new Vector3(0.24f, 0.32f, 0.18f);
                eyeObj.GetComponent<Renderer>().sharedMaterial = eyeBlackMat;
                var eCol = eyeObj.GetComponent<Collider>();
                if (eCol != null) UnityEngine.Object.DestroyImmediate(eCol);

                // Asosiy katta yaltiroq nur (Upper main highlight sparkle)
                var glint1 = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                glint1.name = "Glint_Main";
                glint1.transform.SetParent(eyeObj.transform, false);
                glint1.transform.localPosition = new Vector3(0.18f, 0.28f, 0.42f);
                glint1.transform.localScale = new Vector3(0.48f, 0.48f, 0.35f);
                glint1.GetComponent<Renderer>().sharedMaterial = glintMat;
                var g1Col = glint1.GetComponent<Collider>();
                if (g1Col != null) UnityEngine.Object.DestroyImmediate(g1Col);

                // Kichik qo'shimcha nur (Lower secondary sparkle)
                var glint2 = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                glint2.name = "Glint_Sub";
                glint2.transform.SetParent(eyeObj.transform, false);
                glint2.transform.localPosition = new Vector3(-0.16f, -0.22f, 0.42f);
                glint2.transform.localScale = new Vector3(0.24f, 0.24f, 0.25f);
                glint2.GetComponent<Renderer>().sharedMaterial = glintMat;
                var g2Col = glint2.GetComponent<Collider>();
                if (g2Col != null) UnityEngine.Object.DestroyImmediate(g2Col);
            }

            // 3. Yoqimli Tabassum (Cute smiling mouth)
            var mouthObj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            mouthObj.name = "Mouth";
            mouthObj.transform.SetParent(body.transform, false);
            mouthObj.transform.localPosition = new Vector3(0, -0.15f, 0.45f);
            mouthObj.transform.localRotation = Quaternion.Euler(75f, 0, 0);
            mouthObj.transform.localScale = new Vector3(0.16f, 0.04f, 0.10f);
            var mouthMat = new Material(litShader) { color = new Color(0.08f, 0.08f, 0.12f), name = "M_Mouth" };
            mouthObj.GetComponent<Renderer>().sharedMaterial = mouthMat;
            var mCol = mouthObj.GetComponent<Collider>();
            if (mCol != null) UnityEngine.Object.DestroyImmediate(mCol);

            // 4. Orqadagi Hilpiraydigan Bayroq (Flagpole on back)
            var poleObj = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            poleObj.name = "Pole";
            poleObj.transform.SetParent(root.transform, false);
            poleObj.transform.localPosition = new Vector3(0, 1.45f, -0.55f);
            poleObj.transform.localScale = new Vector3(0.06f, 0.85f, 0.06f);
            var poleMat = new Material(litShader) { color = new Color(0.88f, 0.90f, 0.95f), name = "M_SilverPole" };
            poleObj.GetComponent<Renderer>().sharedMaterial = poleMat;
            var pCol = poleObj.GetComponent<Collider>();
            if (pCol != null) UnityEngine.Object.DestroyImmediate(pCol);

            var finialObj = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            finialObj.name = "Finial";
            finialObj.transform.SetParent(root.transform, false);
            finialObj.transform.localPosition = new Vector3(0, 2.32f, -0.55f);
            finialObj.transform.localScale = Vector3.one * 0.22f;
            var finMat = new Material(litShader) { color = new Color(0.98f, 0.78f, 0.15f), name = "M_GoldFinial" };
            finialObj.GetComponent<Renderer>().sharedMaterial = finMat;
            var fnCol = finialObj.GetComponent<Collider>();
            if (fnCol != null) UnityEngine.Object.DestroyImmediate(fnCol);

            var flagObj = GameObject.CreatePrimitive(PrimitiveType.Quad);
            flagObj.name = "Flag";
            flagObj.transform.SetParent(root.transform, false);
            flagObj.transform.localPosition = new Vector3(0.50f, 1.95f, -0.55f);
            flagObj.transform.localRotation = Quaternion.Euler(0, 90f, 0);
            flagObj.transform.localScale = new Vector3(0.98f, 0.65f, 1.0f);

            Sprite flagSprite = Resources.Load<Sprite>($"Flags/png/{countryCode.ToUpperInvariant()}");
            var flagMat = new Material(litShader) { name = $"M_Flag_{countryCode}" };
            if (flagSprite != null)
            {
                flagMat.mainTexture = flagSprite.texture;
                flagMat.color = Color.white;
            }
            else
            {
                flagMat.color = bodyColor;
            }
            flagObj.GetComponent<Renderer>().sharedMaterial = flagMat;
            var fCol = flagObj.GetComponent<Collider>();
            if (fCol != null) UnityEngine.Object.DestroyImmediate(fCol);

            // 5. Harakat va Yurish Animatori
            var anim = root.AddComponent<CharacterAnimator>();
            anim.Body = body.transform;
            anim.Flag = flagObj.transform;

            // 6. Trigger Collider
            var rootCol = root.AddComponent<CapsuleCollider>();
            rootCol.center = new Vector3(0, 0.85f, 0);
            rootCol.radius = 0.85f;
            rootCol.height = 1.7f;
            rootCol.isTrigger = true;

            return root;
        }
    }
}
