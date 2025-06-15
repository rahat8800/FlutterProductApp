import Foundation
import UIKit

class DeviceInfoFetcher {
  func getDeviceInfo() -> [String: String] {
    let device = UIDevice.current
    let model = device.model
    let systemVersion = device.systemVersion
    return ["model": model, "systemVersion": systemVersion]
  }
}
