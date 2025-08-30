#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include <shobjidl_core.h>

#include "flutter_window.h"
#include "utils.h"
#include "shortcut_helper.h"
#include <fstream>
#include <sstream>
#include <shlwapi.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // Ensure the process has an explicit AppUserModelID so Windows Toasts
  // and activation will be associated with this application. This must be
  // set early during process startup.
  // Note: a matching shortcut in the Start Menu with the same AppUserModelID
  // is required for toasts to activate the application reliably. The
  // Dart-side local_notifier.setup(..., ShortcutPolicy.requireCreate) attempts
  // to create it on first run.
  ::SetCurrentProcessExplicitAppUserModelID(L"com.example.ahadith_alzakah");

  // Ensure a Start Menu shortcut exists with the same AppUserModelID so
  // toast activation works. This is a best-effort call.
  bool shortcut_ok = shortcut_helper::EnsureShortcutWithAppID(L"com.example.ahadith_alzakah", L"أحاديث الزكاة");
  if (shortcut_ok) {
    OutputDebugStringW(L"[main] EnsureShortcutWithAppID succeeded\n");
  } else {
    OutputDebugStringW(L"[main] EnsureShortcutWithAppID failed\n");
  }

  // Diagnostic: write a small log to %TEMP% to capture whether the process
  // was launched with activation args (helpful when clicking Action Center)
  try {
    wchar_t tempPath[MAX_PATH];
    if (GetTempPathW(MAX_PATH, tempPath) > 0) {
      std::wstring logPath = std::wstring(tempPath) + L"ahadith_launch_log.txt";
      std::wofstream logFile;
      logFile.open(logPath, std::ios::out | std::ios::app);
      if (logFile.is_open()) {
        logFile << L"----- Launch at " << std::chrono::system_clock::to_time_t(std::chrono::system_clock::now()) << L" -----\n";
        logFile << (shortcut_ok ? L"EnsureShortcutWithAppID: OK\n" : L"EnsureShortcutWithAppID: FAILED\n");
        // Raw command line
        LPWSTR cmd = GetCommandLineW();
        if (cmd) {
          logFile << L"CommandLine: " << cmd << L"\n";
        }
        logFile << L"----------------------------------------\n";
        logFile.close();
      }
    }
  } catch (...) {
    // swallow; diagnostics should not prevent startup
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"ahadith_alzakah", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
