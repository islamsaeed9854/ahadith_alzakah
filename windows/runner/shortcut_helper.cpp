#include "shortcut_helper.h"
#include <windows.h>
#include <shlobj.h>
#include <shobjidl.h>
#include <propvarutil.h>
#include <propkey.h>
#include <string>
#include <sstream>
#include <iostream>

namespace shortcut_helper {

bool EnsureShortcutWithAppID(const std::wstring& appId, const std::wstring& shortcutName) {
  // Debug: announce entering the helper
  OutputDebugStringW(L"[shortcut_helper] EnsureShortcutWithAppID start\n");

  wchar_t* startMenuPath = nullptr;
  if (FAILED(SHGetKnownFolderPath(FOLDERID_StartMenu, 0, nullptr, &startMenuPath))) {
    OutputDebugStringW(L"[shortcut_helper] SHGetKnownFolderPath FAILED\n");
    return false;
  }

  std::wstring shortcutDir = std::wstring(startMenuPath) + L"\\Programs";
  CoTaskMemFree(startMenuPath);

  std::wstring shortcutPath = shortcutDir + L"\\" + shortcutName + L".lnk";

  // If the shortcut already exists, assume it's correct.
  if (GetFileAttributesW(shortcutPath.c_str()) != INVALID_FILE_ATTRIBUTES) {
    OutputDebugStringW(L"[shortcut_helper] Shortcut already exists: ");
    OutputDebugStringW(shortcutPath.c_str());
    OutputDebugStringW(L"\n");
    return true;
  }

  // Create the Programs folder if missing
  CreateDirectoryW(shortcutDir.c_str(), nullptr);

  HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  bool created = false;
  if (SUCCEEDED(hr)) {
    IShellLinkW* psl = nullptr;
    hr = CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_PPV_ARGS(&psl));
    if (SUCCEEDED(hr) && psl) {
      OutputDebugStringW(L"[shortcut_helper] Created IShellLink instance\n");
      // Set the path to the current executable
      wchar_t exePath[MAX_PATH];
      GetModuleFileNameW(nullptr, exePath, MAX_PATH);
      OutputDebugStringW(L"[shortcut_helper] Executable path: ");
      OutputDebugStringW(exePath);
      OutputDebugStringW(L"\n");
      psl->SetPath(exePath);
      psl->SetArguments(L"");

      // Query for IPropertyStore to set AppUserModelID
      IPropertyStore* pps = nullptr;
      hr = psl->QueryInterface(IID_PPV_ARGS(&pps));
      if (SUCCEEDED(hr) && pps) {
        OutputDebugStringW(L"[shortcut_helper] Obtained IPropertyStore\n");
        PROPVARIANT pv;
        hr = InitPropVariantFromString(appId.c_str(), &pv);
        if (SUCCEEDED(hr)) {
          // Set the AppUserModelID property on the shortcut
          hr = pps->SetValue(PKEY_AppUserModel_ID, pv);
          if (SUCCEEDED(hr)) {
            pps->Commit();

            // Persist the shortcut to disk
            IPersistFile* ppf = nullptr;
            hr = psl->QueryInterface(IID_PPV_ARGS(&ppf));
            if (SUCCEEDED(hr) && ppf) {
              hr = ppf->Save(shortcutPath.c_str(), TRUE);
              if (SUCCEEDED(hr)) {
                created = true;
                OutputDebugStringW(L"[shortcut_helper] Shortcut saved to: ");
                OutputDebugStringW(shortcutPath.c_str());
                OutputDebugStringW(L"\n");
              } else {
                // Report HRESULT code
                wchar_t buf[128];
                swprintf_s(buf, L"[shortcut_helper] IPersistFile::Save failed hr=0x%08X\n", hr);
                OutputDebugStringW(buf);
              }
              ppf->Release();
            } else {
              OutputDebugStringW(L"[shortcut_helper] QueryInterface for IPersistFile failed\n");
            }
          } else {
            wchar_t buf[128];
            swprintf_s(buf, L"[shortcut_helper] IPropertyStore::SetValue failed hr=0x%08X\n", hr);
            OutputDebugStringW(buf);
          }
          PropVariantClear(&pv);
        } else {
          OutputDebugStringW(L"[shortcut_helper] InitPropVariantFromString failed\n");
        }
        pps->Release();
      }
      psl->Release();
    }
    CoUninitialize();
  }

  return created;
}

} // namespace shortcut_helper
