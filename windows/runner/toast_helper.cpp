#include "toast_helper.h"

#include <winrt/Windows.Data.Xml.Dom.h>
#include <winrt/Windows.UI.Notifications.h>
#include <winrt/base.h>
#include <windows.h>
#include <string>

using namespace winrt;
using namespace Windows::Data::Xml::Dom;
using namespace Windows::UI::Notifications;

namespace toast_helper {

bool ShowToast(const std::wstring& title, const std::wstring& body, const std::wstring& arguments) {
  try {
    init_apartment();

    std::wstring xml = L"<toast activationType=\"foreground\" launch=\"" + arguments + L"\">"
                          L"<visual>"
                          L"  <binding template=\"ToastGeneric\">"
                          L"    <text>" + title + L"</text>"
                          L"    <text>" + body + L"</text>"
                          L"  </binding>"
                          L"</visual>"
                          L"</toast>";

    XmlDocument doc;
    doc.LoadXml(xml);

    // Default to the system notifier if no AppUserModelID is provided
    auto notifier = ToastNotificationManager::CreateToastNotifier();
    ToastNotification toast{doc};
    notifier.Show(toast);

    return true;
  } catch (...) {
    return false;
  }
}

// Overload that accepts AppUserModelID and uses CreateToastNotifier(appId)
bool ShowToast(const std::wstring& title, const std::wstring& body, const std::wstring& arguments, const std::wstring& appUserModelId) {
  try {
    init_apartment();

    std::wstring xml = L"<toast activationType=\"foreground\" launch=\"" + arguments + L"\">"
                          L"<visual>"
                          L"  <binding template=\"ToastGeneric\">"
                          L"    <text>" + title + L"</text>"
                          L"    <text>" + body + L"</text>"
                          L"  </binding>"
                          L"</visual>"
                          L"</toast>";

    XmlDocument doc;
    doc.LoadXml(xml);

    // Use the app-specific notifier so activation goes to the correct AppUserModelID
  auto notifier = ToastNotificationManager::CreateToastNotifier(winrt::hstring(appUserModelId));
    ToastNotification toast{doc};
    notifier.Show(toast);

    // Log success via OutputDebugString
    OutputDebugStringW(L"[toast_helper] ShowToast with AppUserModelID called\n");
    return true;
  } catch (...) {
    return false;
  }
}

} // namespace toast_helper
