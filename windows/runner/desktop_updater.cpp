#include "desktop_updater.h"

#include <winsparkle.h>

#include <atomic>
#include <string>
#include <variant>

namespace {

constexpr char kUpdateChannel[] =
    "com.makerjackie.onesend/desktop_updater";
constexpr char kAppcastUrl[] =
    "https://onesend.01mvp.com/updates/appcast.xml";
constexpr char kPublicEd25519Key[] =
    "zkX233D6ILzCJFNMMlmEY3ilrRAAG/ejsbZAMCUyBUI=";
constexpr wchar_t kWinSparkleRegistryKey[] =
    L"Software\\com.makerjackie\\OneSend\\WinSparkle";
constexpr char kWinSparkleRegistryPath[] =
    "Software\\com.makerjackie\\OneSend\\WinSparkle";

std::atomic<HWND> g_host_window{nullptr};

std::wstring WidenAscii(const char* value) {
  return std::wstring(value, value + std::char_traits<char>::length(value));
}

bool HasAutomaticUpdatePreference() {
  HKEY key = nullptr;
  const auto opened = RegOpenKeyExW(HKEY_CURRENT_USER, kWinSparkleRegistryKey,
                                    0, KEY_QUERY_VALUE, &key);
  if (opened != ERROR_SUCCESS) {
    return false;
  }

  DWORD type = 0;
  DWORD size = 0;
  const auto queried =
      RegQueryValueExW(key, L"CheckForUpdates", nullptr, &type, nullptr, &size);
  RegCloseKey(key);
  return queried == ERROR_SUCCESS;
}

int __cdecl CanShutdownForUpdate() {
  if (g_host_window.load(std::memory_order_acquire) == nullptr) {
    return FALSE;
  }
  return TRUE;
}

void __cdecl RequestShutdownForUpdate() {
  const auto host_window = g_host_window.load(std::memory_order_acquire);
  if (host_window != nullptr) {
    PostMessageW(host_window, WM_CLOSE, 0, 0);
  }
}

}  // namespace

DesktopUpdater::DesktopUpdater(flutter::BinaryMessenger* messenger,
                               HWND host_window)
    : channel_(
          std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
              messenger, kUpdateChannel,
              &flutter::StandardMethodCodec::GetInstance())) {
  g_host_window.store(host_window, std::memory_order_release);

  const auto app_version = WidenAscii(FLUTTER_VERSION);
  const auto build_version = std::to_wstring(FLUTTER_VERSION_BUILD);
  win_sparkle_set_app_details(L"com.makerjackie", L"OneSend",
                              app_version.c_str());
  win_sparkle_set_app_build_version(build_version.c_str());
  win_sparkle_set_registry_path(kWinSparkleRegistryPath);
  win_sparkle_set_appcast_url(kAppcastUrl);
  if (!win_sparkle_set_eddsa_public_key(kPublicEd25519Key)) {
    return;
  }

  win_sparkle_set_can_shutdown_callback(CanShutdownForUpdate);
  win_sparkle_set_shutdown_request_callback(RequestShutdownForUpdate);
  win_sparkle_set_update_check_interval(24 * 60 * 60);
  if (!HasAutomaticUpdatePreference()) {
    win_sparkle_set_automatic_check_for_updates(1);
  }

  channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      });

  win_sparkle_init();
  initialized_ = true;
}

DesktopUpdater::~DesktopUpdater() {
  channel_->SetMethodCallHandler(nullptr);
  g_host_window.store(nullptr, std::memory_order_release);
  if (initialized_) {
    win_sparkle_cleanup();
  }
}

void DesktopUpdater::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  if (!initialized_) {
    result->Error("initialization_failed",
                  "WinSparkle could not initialize its signing key.");
    return;
  }

  if (call.method_name() == "checkForUpdates") {
    win_sparkle_check_update_with_ui();
    result->Success();
    return;
  }

  if (call.method_name() == "getAutomaticChecksEnabled") {
    result->Success(flutter::EncodableValue(
        win_sparkle_get_automatic_check_for_updates() != 0));
    return;
  }

  if (call.method_name() == "setAutomaticChecksEnabled") {
    const auto* arguments = std::get_if<flutter::EncodableMap>(call.arguments());
    if (arguments == nullptr) {
      result->Error("invalid_arguments", "The enabled boolean is required.");
      return;
    }
    const auto value = arguments->find(flutter::EncodableValue("enabled"));
    if (value == arguments->end() ||
        !std::holds_alternative<bool>(value->second)) {
      result->Error("invalid_arguments", "The enabled boolean is required.");
      return;
    }
    win_sparkle_set_automatic_check_for_updates(
        std::get<bool>(value->second) ? 1 : 0);
    result->Success();
    return;
  }

  result->NotImplemented();
}
