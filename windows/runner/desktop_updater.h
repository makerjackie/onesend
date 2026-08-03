#ifndef RUNNER_DESKTOP_UPDATER_H_
#define RUNNER_DESKTOP_UPDATER_H_

#include <flutter/binary_messenger.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

// Owns WinSparkle for the lifetime of the Flutter host window.
class DesktopUpdater {
 public:
  DesktopUpdater(flutter::BinaryMessenger* messenger, HWND host_window);
  ~DesktopUpdater();

  DesktopUpdater(const DesktopUpdater&) = delete;
  DesktopUpdater& operator=(const DesktopUpdater&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);

  bool initialized_ = false;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif  // RUNNER_DESKTOP_UPDATER_H_
