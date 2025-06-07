import Metal
import SwiftUI

struct DeviceProperty : Identifiable {
    typealias ID = String
    var id: ID { return title }

    let title: String
    let value: String
}

struct MetalDevice : Identifiable {
    typealias ID = String
    var id: ID { return device.name }

    let device: MTLDevice
    let properties: [DeviceProperty]

    init(_ device: MTLDevice) {
        var props = [DeviceProperty]()

        let formatStyle = Measurement<UnitInformationStorage>.FormatStyle.ByteCount(style: .decimal,
                                                                                    allowedUnits: [.mb, .gb],
                                                                                    spellsOutZero: false,
                                                                                    includesActualByteCount: false,
                                                                                    locale: Locale.current)
        let workingSet = Measurement<UnitInformationStorage>(value: Double(device.recommendedMaxWorkingSetSize),
                                                             unit: .bytes)
        props.append(DeviceProperty(title: "Max Working Set", value: workingSet.formatted(formatStyle)))

        props.append(DeviceProperty(title: "Has Unified Memory?", value: String(describing: device.hasUnifiedMemory)))

        props.append(DeviceProperty(title: "Supports Metal 3?", value: String(describing: device.supportsFamily(.metal3))))

        props.append(DeviceProperty(title: "Supports raytracing?", value: String(describing: device.supportsRaytracing)))

        self.device = device
        self.properties = props
    }
}

struct DevicePropertyRow: View {
    @State var property: DeviceProperty

    var body: some View {
        HStack {
            Text(property.title)
            Spacer()
            Text(property.value)
        }
    }
}

struct ContentView: View {
    var body: some View {
        List {
            ForEach(MTLCopyAllDevices().map { MetalDevice($0) }) { deviceWrapper in
                Section(header: Text(deviceWrapper.device.name).font(.headline)) {
                    ForEach(deviceWrapper.properties) {
                        DevicePropertyRow(property: $0)
                    }
                }
            }
        }
    }
}

@main
struct MetalDeviceCheckApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#Preview {
    ContentView()
}
