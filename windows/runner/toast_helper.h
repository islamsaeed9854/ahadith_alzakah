#pragma once

#include <string>

namespace toast_helper {
  bool ShowToast(const std::wstring& title, const std::wstring& body, const std::wstring& arguments, const std::wstring& appUserModelId);
}
