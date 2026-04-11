import AVFoundation
import Flutter
import UIKit

final class SpeechPlugin: NSObject, FlutterPlugin, AVSpeechSynthesizerDelegate {
  private let synthesizer = AVSpeechSynthesizer()
  private var language = "zh-CN"
  private var rate = Float(0.48)
  private var pitch = Float(1.0)
  private var pendingSpeakResult: FlutterResult?

  override init() {
    super.init()
    synthesizer.delegate = self
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "aidrun/speech", binaryMessenger: registrar.messenger())
    let instance = SpeechPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "configure":
      guard let args = call.arguments as? [String: Any] else {
        result(nil)
        return
      }
      configure(with: args)
      result(nil)
    case "speak":
      guard
        let args = call.arguments as? [String: Any],
        let text = args["text"] as? String,
        !text.isEmpty
      else {
        result(nil)
        return
      }
      speak(text: text, result: result)
    case "stop":
      stopSpeaking()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    resolvePendingSpeak()
  }

  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
    resolvePendingSpeak()
  }

  private func configure(with args: [String: Any]) {
    if let value = args["language"] as? String, !value.isEmpty {
      language = value
    }
    if let value = args["rate"] as? Double {
      rate = Float(value)
    }
    if let value = args["pitch"] as? Double {
      pitch = Float(value)
    }
  }

  private func speak(text: String, result: @escaping FlutterResult) {
    if let pendingSpeakResult {
      pendingSpeakResult(nil)
      self.pendingSpeakResult = nil
    }
    if synthesizer.isSpeaking {
      synthesizer.stopSpeaking(at: .immediate)
    }

    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = AVSpeechSynthesisVoice(language: language)
    utterance.rate = rate
    utterance.pitchMultiplier = pitch

    pendingSpeakResult = result
    synthesizer.speak(utterance)
  }

  private func stopSpeaking() {
    if synthesizer.isSpeaking || synthesizer.isPaused {
      synthesizer.stopSpeaking(at: .immediate)
    }
    resolvePendingSpeak()
  }

  private func resolvePendingSpeak() {
    guard let pendingSpeakResult else {
      return
    }
    self.pendingSpeakResult = nil
    pendingSpeakResult(nil)
  }
}
