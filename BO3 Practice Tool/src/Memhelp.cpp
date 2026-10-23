#include "memHelp.h"

#include <TlHelp32.h>
#include <sstream>
#include <cstring>

#include "Walnut/Logger.h"

namespace BO3PT
{
    DWORD MemState::s_PID;
    HANDLE MemState::s_Handle;
    void* MemState::s_BaseAddress;
    void* MemState::s_MapNameAddress;
    void* MemState::s_RoundAddress;
    int MemState::s_RoundValue;
    char MemState::s_MapNameValue[14];
    MemStates MemState::s_State;
    GameBuild MemState::s_Build = BuildUnknown;
    int MemState::s_BuildOverride = 0;
    uint32_t MemState::s_ExeTimestamp = 0;
    void* MemState::s_MapCandidates[2];
    void* MemState::s_RoundCandidates[2];
    int MemState::s_MapPick = -1;
    int MemState::s_RoundPick = -1;

    // Addresses (offsets from BlackOps3.exe's base) for the downpatched March 2023 exe.
    static constexpr uintptr_t MAP_NAME_2023 = 0x179DF840;
    static constexpr uintptr_t ROUND_2023 = 0xA55BDEC;
    // The 2026 Steam updates moved the game's globals down by 0x7F000 (0x7EF80 past 0x168ED7F4).
    // Which of the two applies to these values isn't certain, so both are tried and the one
    // holding a real value is kept.
    static constexpr uintptr_t SHIFTS_2026[2] = { 0x7EF80, 0x7F000 };
    // Any exe linked on/after 1 Jan 2026 is one of the 2026 updates; the downpatched exe is from 2023.
    static constexpr uint32_t TIMESTAMP_2026 = 1767225600;

    const char* MemState::BuildName(GameBuild build)
    {
        switch (build) {
        case Build2023: return "Downpatched (March 2023)";
        case Build2026: return "Current Steam (2026 update)";
        default: return "Unknown";
        }
    }

    GameBuild MemState::BuildFromTimestamp(uint32_t timestamp)
    {
        if (!timestamp) {
            return BuildUnknown;
        }
        return timestamp >= TIMESTAMP_2026 ? Build2026 : Build2023;
    }

    GameBuild MemState::ResolveBuild(GameBuild detected)
    {
        if (s_BuildOverride == 1) return Build2023;
        if (s_BuildOverride == 2) return Build2026;
        return detected;
    }

    GameBuild MemState::DetectBuildFromFile(const std::string& exePath, uint32_t* timestampOut)
    {
        uint32_t timestamp = 0;
        HANDLE file = CreateFileA(exePath.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
        if (file != INVALID_HANDLE_VALUE) {
            unsigned char header[0x1000] = { 0 };
            DWORD read = 0;
            if (ReadFile(file, header, sizeof(header), &read, NULL) && read >= 0x40) {
                uint32_t peOffset = *reinterpret_cast<uint32_t*>(header + 0x3C);
                if (peOffset + 12 <= read && !memcmp(header + peOffset, "PE\0\0", 4)) {
                    timestamp = *reinterpret_cast<uint32_t*>(header + peOffset + 8);
                }
            }
            CloseHandle(file);
        }
        if (timestampOut) {
            *timestampOut = timestamp;
        }
        return BuildFromTimestamp(timestamp);
    }

    bool MemState::ValidMapName(const char* name)
    {
        size_t len = strnlen(name, 13);
        if (len < 4) {
            return false;
        }
        for (size_t i = 0; i < len; i++) {
            char c = name[i];
            if (!((c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_')) {
                return false;
            }
        }
        return !strncmp(name, "zm_", 3) || !strncmp(name, "cp_", 3) || !strncmp(name, "mp_", 3) || !strncmp(name, "core_", 5);
    }

    void* MemState::GetModuleBaseAddress(uint32_t processID, const wchar_t* moduleName)
    {
        void* hSnap = nullptr;
        MODULEENTRY32W Mod32 = { 0 };

        if ((hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, processID)) == INVALID_HANDLE_VALUE) {
            return 0;
        }

        Mod32.dwSize = sizeof(MODULEENTRY32W);
        while (Module32NextW(hSnap, &Mod32)) {
            if (!_wcsicmp(moduleName, Mod32.szModule)) {
                CloseHandle(hSnap);
                return (void*)Mod32.modBaseAddr;
            }
        }

        CloseHandle(hSnap);
        return nullptr;
    }

    DWORD MemState::GetProcessIdByName(const wchar_t* processName)
    {
        PROCESSENTRY32W pt = { 0 };
        HANDLE hsnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
        pt.dwSize = sizeof(PROCESSENTRY32W);
        Walnut::Logger::Log(Walnut::MessageType::Info, "Starting Enumeration");
        if (Process32FirstW(hsnap, &pt)) {
            do {
                if (!_wcsicmp(pt.szExeFile, processName)) {
                    Walnut::Logger::Log(Walnut::MessageType::Success, "BlackOps3.exe Found");
                    CloseHandle(hsnap);
                    return pt.th32ProcessID;
                }
            } while (Process32NextW(hsnap, &pt));
        }
        Walnut::Logger::Log(Walnut::MessageType::Warning, "BlackOps3.exe Not Found");
        CloseHandle(hsnap);
        return 0;
    }

    bool MemState::SetPID(const wchar_t* moduleName)
    {
        s_PID = GetProcessIdByName(moduleName);
        if (s_PID != NULL) {
            s_State = Loaded;
            return true;
        }
        return false;
    }

    bool MemState::SetAddresses(const wchar_t* moduleName)
    {
        s_BaseAddress = GetModuleBaseAddress(s_PID, moduleName);
        if (s_BaseAddress == nullptr) {
            s_State = Unloaded;
            return false;
        }
        const uintptr_t base = reinterpret_cast<uintptr_t>(s_BaseAddress);

        // the running exe's link timestamp says which build it is
        s_ExeTimestamp = 0;
        HANDLE probe = OpenProcess(PROCESS_VM_READ | PROCESS_QUERY_INFORMATION, false, s_PID);
        if (probe) {
            uint32_t peOffset = 0;
            if (ReadProcessMemory(probe, reinterpret_cast<void*>(base + 0x3C), &peOffset, sizeof(peOffset), NULL) && peOffset < 0x1000) {
                ReadProcessMemory(probe, reinterpret_cast<void*>(base + peOffset + 8), &s_ExeTimestamp, sizeof(s_ExeTimestamp), NULL);
            }
            CloseHandle(probe);
        }
        s_Build = ResolveBuild(BuildFromTimestamp(s_ExeTimestamp));
        if (s_Build == BuildUnknown) {
            s_Build = Build2023;
        }
        Walnut::Logger::Log(Walnut::MessageType::Info, std::string("Game build: ") + BuildName(s_Build));

        s_MapPick = -1;
        s_RoundPick = -1;
        s_RoundValue = 0;
        memset(s_MapNameValue, 0, sizeof(s_MapNameValue));
        if (s_Build == Build2026) {
            for (int i = 0; i < 2; i++) {
                s_MapCandidates[i] = reinterpret_cast<void*>(base + MAP_NAME_2023 - SHIFTS_2026[i]);
                s_RoundCandidates[i] = reinterpret_cast<void*>(base + ROUND_2023 - SHIFTS_2026[1 - i]);
            }
            s_MapNameAddress = s_MapCandidates[0];
            s_RoundAddress = s_RoundCandidates[0];
        }
        else {
            s_MapNameAddress = reinterpret_cast<void*>(base + MAP_NAME_2023);
            s_RoundAddress = reinterpret_cast<void*>(base + ROUND_2023);
            s_MapPick = 0;
            s_RoundPick = 0;
        }
        return true;
    }

    bool MemState::SetHandle()
    {
        s_Handle = OpenProcess(PROCESS_VM_READ, false, s_PID);
        if (s_Handle == NULL || s_Handle == INVALID_HANDLE_VALUE) {
            s_State = Unloaded;
            return false;
        }
        return true;
    }

    bool MemState::ReadData()
    {
        auto fail = []() {
            s_State = Unloaded;
            s_Handle = NULL;
            return false;
        };
        if (s_Handle == NULL || s_Handle == INVALID_HANDLE_VALUE) {
            return fail();
        }

        // the downpatched exe: fixed addresses
        if (s_MapPick >= 0 && s_RoundPick >= 0) {
            if (!ReadProcessMemory(s_Handle, s_MapNameAddress, &s_MapNameValue, 13, NULL) ||
                !ReadProcessMemory(s_Handle, s_RoundAddress, &s_RoundValue, sizeof(s_RoundValue), NULL)) {
                return fail();
            }
            s_MapNameValue[13] = 0;
            return true;
        }

        // the 2026 exe: use whichever candidate address holds a real map name / round
        if (s_MapPick < 0) {
            char name[14] = { 0 };
            bool anyRead = false;
            for (int i = 0; i < 2; i++) {
                if (!ReadProcessMemory(s_Handle, s_MapCandidates[i], name, 13, NULL)) {
                    continue;
                }
                anyRead = true;
                name[13] = 0;
                if (ValidMapName(name)) {
                    s_MapPick = i;
                    s_MapNameAddress = s_MapCandidates[i];
                    std::stringstream log;
                    log << "Map name found at " << s_MapNameAddress << " (" << name << ")";
                    Walnut::Logger::Log(Walnut::MessageType::Success, log.str());
                    break;
                }
            }
            if (!anyRead) {
                return fail();
            }
        }
        if (s_MapPick >= 0) {
            if (!ReadProcessMemory(s_Handle, s_MapNameAddress, &s_MapNameValue, 13, NULL)) {
                return fail();
            }
            s_MapNameValue[13] = 0;
            if (!ValidMapName(s_MapNameValue)) {
                s_MapNameValue[0] = 0; // mid-load: treat as unknown rather than "left the map"
            }
        }
        else {
            s_MapNameValue[0] = 0; // not found yet: unknown map, so nothing gets reset by mistake
        }

        if (s_RoundPick < 0) {
            // only lock the round in once a zombies game is running and a candidate holds a real round
            s_RoundValue = 0;
            if (!strncmp(s_MapNameValue, "zm_", 3)) {
                for (int i = 0; i < 2; i++) {
                    int value = 0;
                    if (ReadProcessMemory(s_Handle, s_RoundCandidates[i], &value, sizeof(value), NULL) && value >= 1 && value <= 255) {
                        s_RoundPick = i;
                        s_RoundAddress = s_RoundCandidates[i];
                        s_RoundValue = value;
                        std::stringstream log;
                        log << "Round found at " << s_RoundAddress << " (round " << value << ")";
                        Walnut::Logger::Log(Walnut::MessageType::Success, log.str());
                        break;
                    }
                }
            }
        }
        else if (!ReadProcessMemory(s_Handle, s_RoundAddress, &s_RoundValue, sizeof(s_RoundValue), NULL)) {
            return fail();
        }
        return true;
    }
}
