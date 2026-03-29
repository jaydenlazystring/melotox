import ManagedSettings

#if canImport(ManagedSettingsUI)
import ManagedSettingsUI

class MelotoxShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        return ShieldConfiguration()
    }
}
#endif
