#if UNITY_EDITOR
using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

namespace ColorLand.Editor
{
    public static class AndroidBuilder
    {
        [MenuItem("ColorLand/Build Android APK")]
        public static void BuildAndroid()
        {
            Debug.Log("ColorLand: Android APK yig'ish boshlandi...");

            string sdkPath = @"C:\Users\TradePOS7\AppData\Local\Android\Sdk";
            string jdkPath = @"C:\Program Files\Microsoft\jdk-17.0.20.101-hotspot";
            string ndkPath = @"C:\Users\TradePOS7\AppData\Local\Android\Sdk\ndk\27.2.12479018";

            // EditorPrefs
            EditorPrefs.SetString("AndroidSdkRoot", sdkPath);
            EditorPrefs.SetString("JdkPath", jdkPath);
            EditorPrefs.SetString("AndroidNdkRoot", ndkPath);
            EditorPrefs.SetString("AndroidNdkRootR23b", ndkPath);
            EditorPrefs.SetString("AndroidNdkRootR25b", ndkPath);

            // Reflection orqali AndroidExternalToolsSettings ni o'rnatish
            foreach (var asm in AppDomain.CurrentDomain.GetAssemblies())
            {
                Type type = asm.GetType("UnityEditor.Android.AndroidExternalToolsSettings");
                if (type != null)
                {
                    SetStaticProp(type, "sdkRootPath", sdkPath);
                    SetStaticProp(type, "jdkRootPath", jdkPath);
                    SetStaticProp(type, "ndkRootPath", ndkPath);
                }

                // SDKManager ga o'rnatilgan paketlar ro'yxatini ro'yxatdan o'tkazish
                Type sdkMgrType = asm.GetType("UnityEditor.Android.SDKManager");
                if (sdkMgrType != null)
                {
                    try
                    {
                        var searchType = asm.GetType("UnityEditor.Android.SDKManager+SearchType");
                        var compType = asm.GetType("UnityEditor.Android.SDKManager+Component");
                        var inst = sdkMgrType.GetMethod("GetInstance", Type.EmptyTypes)?.Invoke(null, null);
                        var addMethod = sdkMgrType.GetMethod("AddVersionToList", BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance);

                        if (inst != null && addMethod != null && searchType != null && compType != null)
                        {
                            object installed = Enum.Parse(searchType, "Installed");
                            object platTools = Enum.Parse(compType, "PlatformTools");
                            object buildTools = Enum.Parse(compType, "BuildTools");
                            object platform = Enum.Parse(compType, "Platform");
                            object cmdTools = Enum.Parse(compType, "CmdLineTools");

                            addMethod.Invoke(inst, new object[] { installed, platTools, new Version(37, 0, 1) });
                            addMethod.Invoke(inst, new object[] { installed, buildTools, new Version(35, 0, 0) });
                            addMethod.Invoke(inst, new object[] { installed, buildTools, new Version(36, 0, 0) });
                            addMethod.Invoke(inst, new object[] { installed, platform, new Version(34, 0, 0) });
                            addMethod.Invoke(inst, new object[] { installed, platform, new Version(35, 0, 0) });
                            addMethod.Invoke(inst, new object[] { installed, cmdTools, new Version(23, 0, 0) });
                            Debug.Log("ColorLand: SDKManager ga komponentlar muvaffaqiyatli ro'yxatga olindi!");
                        }
                    }
                    catch (Exception ex)
                    {
                        Debug.LogWarning($"SDKManager ro'yxatga olish xatosi: {ex.Message}");
                    }
                }
            }

            // Player Settings
            PlayerSettings.companyName = "Shogoyos";
            PlayerSettings.productName = "Color Land 3D";
            PlayerSettings.SetApplicationIdentifier(NamedBuildTarget.Android, "com.shogoyos.colorland3d");
            PlayerSettings.bundleVersion = "8.4.0";
            PlayerSettings.Android.bundleVersionCode = 840;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel24;
            PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevel34;

            // Scripting Backend: IL2CPP, ARM64
            PlayerSettings.SetScriptingBackend(NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;

            string outDir = Path.Combine(Directory.GetCurrentDirectory(), "Builds", "Android");
            if (!Directory.Exists(outDir)) Directory.CreateDirectory(outDir);
            string apkPath = Path.Combine(outDir, "ColorLand3D_v8.4_arm64.apk");

            string[] scenes = { "Assets/Scenes/MainScene.unity" };

            BuildPlayerOptions buildPlayerOptions = new BuildPlayerOptions
            {
                scenes = scenes,
                locationPathName = apkPath,
                target = BuildTarget.Android,
                options = BuildOptions.None
            };

            Debug.Log($"ColorLand: BuildPlayer chaqirilmoqda... APK manzili: {apkPath}");
            BuildReport report = BuildPipeline.BuildPlayer(buildPlayerOptions);
            BuildSummary summary = report.summary;

            if (summary.result == BuildResult.Succeeded)
            {
                Debug.Log($"ColorLand: Android ARM64 APK muvaffaqiyatli yig'ildi! Yo'l: {apkPath}, hajmi: {summary.totalSize} bayt");
            }
            else
            {
                Debug.LogError($"ColorLand: Android yig'ish muvaffaqiyatsiz bo'ldi! Natija: {summary.result}, xatolar: {summary.totalErrors}");
                foreach (var step in report.steps)
                {
                    foreach (var msg in step.messages)
                    {
                        if (msg.type == LogType.Error || msg.type == LogType.Exception)
                        {
                            Debug.LogError($"Step [{step.name}] xatosi: {msg.content}");
                        }
                    }
                }
            }
        }

        private static void SetStaticProp(Type type, string propName, object val)
        {
            try
            {
                var prop = type.GetProperty(propName, BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Static);
                if (prop != null && prop.CanWrite)
                {
                    prop.SetValue(null, val);
                    Debug.Log($"Set {propName} = {val}");
                }
            }
            catch (Exception ex)
            {
                Debug.LogWarning($"SetStaticProp {propName} xatosi: {ex.Message}");
            }
        }
    }
}
#endif
