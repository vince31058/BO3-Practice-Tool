#pragma once
#include <Windows.h>
#include <stdint.h>
#include <string>

namespace BO3PT {

    typedef int MemStates;

    enum MemStates_ {
        Unloaded,
        Loaded
    };

    // Which BlackOps3.exe is running. The injector and the memory addresses differ between them.
    enum GameBuild {
        BuildUnknown,
        Build2023,  // the downpatched March 2023 exe (CODBUILD8-764)
        Build2026   // the current Steam exe (2026 updates)
    };

    class MemState {
    public:
        static void* GetModuleBaseAddress(uint32_t processID, const wchar_t* moduleName);
        static DWORD GetProcessIdByName(const wchar_t* processName);

        static DWORD GetPID() { return s_PID; }
        static HANDLE GetHandle() { return s_Handle; }
        static void* GetBaseAddress() { return s_BaseAddress; }
        static void* GetMapNameAddress() { return s_MapNameAddress; }
        static void* GetRoundAddress() { return s_RoundAddress; }
        static int GetRoundValue() { return s_RoundValue; }
        static char* GetMapNameValue() { return s_MapNameValue; }
        static MemStates GetState() { return s_State; }
        static GameBuild GetBuild() { return s_Build; }
        static uint32_t GetExeTimestamp() { return s_ExeTimestamp; }
        static const char* BuildName(GameBuild build);
        // 0 = detect automatically, 1 = always the downpatched exe, 2 = always the current Steam exe
        static void SetBuildOverride(int buildOverride) { s_BuildOverride = buildOverride; }
        static int GetBuildOverride() { return s_BuildOverride; }
        // reads BlackOps3.exe on disk (for when the game isn't running)
        static GameBuild DetectBuildFromFile(const std::string& exePath, uint32_t* timestampOut = nullptr);
        static GameBuild BuildFromTimestamp(uint32_t timestamp);
        static GameBuild ResolveBuild(GameBuild detected);

        static bool SetPID(const wchar_t* moduleName);
        static bool SetAddresses(const wchar_t* moduleName);
        static bool SetHandle();
        static bool ReadData();
    private:
        static bool ValidMapName(const char* name);
        static GameBuild s_Build;
        static int s_BuildOverride;
        static uint32_t s_ExeTimestamp;
        static void* s_MapCandidates[2];
        static void* s_RoundCandidates[2];
        static int s_MapPick;
        static int s_RoundPick;
        static DWORD s_PID;
        static HANDLE s_Handle;
        static void* s_BaseAddress;
        static void* s_MapNameAddress;
        static void* s_RoundAddress;
        static int s_RoundValue;
        static char s_MapNameValue[14];
        static MemStates s_State;
    };

}