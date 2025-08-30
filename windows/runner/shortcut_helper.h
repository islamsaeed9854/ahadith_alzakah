#pragma once

#include <string>

namespace shortcut_helper {
  // Ensure a Start Menu Programs shortcut exists with the given AppUserModelID.
  // Returns true on success or if the shortcut already exists.
  bool EnsureShortcutWithAppID(const std::wstring& appId, const std::wstring& shortcutName);
}
