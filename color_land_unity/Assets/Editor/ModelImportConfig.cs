using UnityEngine;
using UnityEditor;
using System.IO;

namespace ColorLand.Editor
{
    public class ModelImportConfig : AssetPostprocessor
    {
        private void OnPreprocessTexture()
        {
            if (assetPath.Contains("Resources/UI/") || assetPath.Contains("UI/"))
            {
                var importer = assetImporter as TextureImporter;
                if (importer != null)
                {
                    importer.textureType = TextureImporterType.Sprite;
                    importer.spriteImportMode = SpriteImportMode.Single;
                    importer.alphaIsTransparency = true;
                    importer.mipmapEnabled = false;
                }
            }
        }

        private void OnPreprocessModel()
        {
            if (assetPath.Contains("Models/"))
            {
                var importer = assetImporter as ModelImporter;
                if (importer != null)
                {
                    importer.useFileUnits = false;
                    importer.globalScale = 1.0f;
                    importer.bakeAxisConversion = true;
                    importer.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
                    importer.materialLocation = ModelImporterMaterialLocation.InPrefab;
                }
            }
        }

        [MenuItem("ColorLand/Reimport All Models")]
        public static void ReimportAll()
        {
            string[] dirs = { "Assets/Models", "Assets/Resources/Models" };
            foreach (var dir in dirs)
            {
                if (!Directory.Exists(dir)) continue;
                var files = Directory.GetFiles(dir, "*.fbx");
                foreach (var f in files)
                {
                    string unityPath = f.Replace('\\', '/');
                    var importer = AssetImporter.GetAtPath(unityPath) as ModelImporter;
                    if (importer != null)
                    {
                        importer.useFileUnits = false;
                        importer.globalScale = 1.0f;
                        importer.bakeAxisConversion = true;
                        importer.materialImportMode = ModelImporterMaterialImportMode.ImportStandard;
                        importer.materialLocation = ModelImporterMaterialLocation.InPrefab;
                        importer.SaveAndReimport();
                        Debug.Log($"[REIMPORTED 1:1] {unityPath}");
                    }
                }
            }
            AssetDatabase.Refresh(ImportAssetOptions.ForceSynchronousImport);
        }
    }
}
