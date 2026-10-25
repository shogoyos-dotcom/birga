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

            // 4. Harakat va Yurish Animatori
            var anim = root.AddComponent<CharacterAnimator>();
            anim.Body = body.transform;

            // 5. Trigger Collider
            var rootCol = root.AddComponent<CapsuleCollider>();
            rootCol.center = new Vector3(0, 0.85f, 0);
            rootCol.radius = 0.85f;
            rootCol.height = 1.7f;
            rootCol.isTrigger = true;

            return root;
        }
    }
}
