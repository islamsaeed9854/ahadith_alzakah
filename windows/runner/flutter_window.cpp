#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif
#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include "toast_helper.h"
#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include <codecvt>
#include <locale>
#include <string>

// Forward declaration so we can call RegisterToastMethodChannel() from OnCreate
static void RegisterToastMethodChannel(flutter::FlutterViewController* controller);

// Keep the channel alive for the lifetime of the process
static std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> g_toast_channel = nullptr;

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  // Register native MethodChannel for Windows toast
  // Disabled: revert to Dart-only notifications. Keep code present for future use.
  // RegisterToastMethodChannel(flutter_controller_.get());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

// static void RegisterToastMethodChannel(flutter::FlutterViewController* controller) {
//   // Obtain the BinaryMessenger from the engine
//   auto messenger = controller->engine()->messenger();
//   using flutter::MethodChannel;
//   using flutter::EncodableValue;
//   g_toast_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
//       messenger, "ahadith_alzakah/windows_toast",
//       &flutter::StandardMethodCodec::GetInstance());
//
//   g_toast_channel->SetMethodCallHandler([](const flutter::MethodCall<flutter::EncodableValue>& call, std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
//     if (call.method_name() == "showToast") {
//       OutputDebugStringA("[flutter_window] showToast method called\n");
//       const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
//       if (!args) {
//         OutputDebugStringA("[flutter_window] showToast: bad args - not a map\n");
//         result->Error("bad_args", "Expected map args");
//         return;
//       }
//       // Helper to extract string value from EncodableMap safely
//       auto extract = [&](const std::string& key) -> std::string {
//         auto it = args->find(flutter::EncodableValue(key));
//         if (it == args->end()) return std::string();
//         if (auto p = std::get_if<std::string>(&it->second)) return *p;
//         return std::string();
//       };
//
//       std::string titleUtf8 = extract("title");
//       std::string bodyUtf8 = extract("body");
//       std::string launchUtf8 = extract("launch");
//
//       // Convert utf8 to wstring
//       std::wstring_convert<std::codecvt_utf8<wchar_t>> conv;
//       std::wstring wtitle = conv.from_bytes(titleUtf8);
//       std::wstring wbody = conv.from_bytes(bodyUtf8);
//       std::wstring wlaunch = conv.from_bytes(launchUtf8);
//
//   // Pass the AppUserModelID used in main.cpp so activation maps back to the app.
//   std::wstring appId = L"com.example.ahadith_alzakah";
//   bool ok = toast_helper::ShowToast(wtitle, wbody, wlaunch, appId);
//       if (ok) {
//         OutputDebugStringW(L"[flutter_window] toast_helper::ShowToast returned true\n");
//       } else {
//         OutputDebugStringW(L"[flutter_window] toast_helper::ShowToast returned false\n");
//       }
//       result->Success(flutter::EncodableValue(ok));
//       return;
//     }
//     result->NotImplemented();
//   });
//}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
