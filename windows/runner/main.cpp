#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>
#include <shobjidl.h> // Required for AppUserModelID
#include <shellapi.h> // Required for CommandLineToArgvW
#include <vector>     // Required for std::vector
#include <string>     // Required for std::string

#include "flutter_window.h"
#include "utils.h"
#include "shortcut_helper.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {

  // Use a more robust method to check for the background task argument by searching
  // the raw command line string. Treat scheduler flag as a background launch.
  bool is_background_task = (wcsstr(command_line, L"--show-daily-hadith-background") != nullptr) ||
                            (wcsstr(command_line, L"--show-daily-hadith-scheduler") != nullptr);

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
  
  // Set the AppUserModelID so that Windows can properly associate notifications
  // and shortcuts with this application.
  ::SetCurrentProcessExplicitAppUserModelID(L"com.example.ahadith_alzakah");

  // This is not strictly necessary for the background task, but it's good practice
  // to ensure it's set up for when the user launches the app normally.
  shortcut_helper::EnsureShortcutWithAppID(L"com.example.ahadith_alzakah", L"أحاديث الزكاة");

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // This creates the controller and starts the Dart engine.
  // The Dart code will now run and see the launch arguments.
  FlutterWindow window(project);

  // Only create and show a visible window if it's a normal launch.
  if (!is_background_task) {
    Win32Window::Point origin(10, 10);
    Win32Window::Size size(1280, 720);
    if (!window.Create(L"ahadith_alzakah", origin, size)) {
      return EXIT_FAILURE;
    }
    window.SetQuitOnClose(true);
  }

  // The message loop is required for both UI and headless modes to process events.
  // In headless mode, the Dart `exit(0)` call will terminate this loop.
  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}

