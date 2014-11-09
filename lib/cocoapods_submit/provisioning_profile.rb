require 'plist'

module CocoapodsSubmit
  class ProvisioningProfile
    def initialize(hash)
      @hash = hash
    end

    def self.from_uuid(uuid)
      from_file File.expand_path File.join "~/Library/MobileDevice/Provisioning Profiles", "#{uuid}.mobileprovision"
    end

    def rank
      return 0.0 unless @hash

      rank = 1.0
      rank *= 0.0 if @hash["Entitlements"]["get-task-allow"]
      rank *= 1.0 / @hash["ProvisionedDevices"].count if @hash["ProvisionedDevices"]

      return rank
    end

    def self.from_file(path)
      return nil unless File.exists? path

      start_string = "<?"
      end_string = "</plist>"

      profile = File.read(path)
      profile = profile.slice(profile.index(start_string), profile.length)
      profile = profile.slice(0, profile.index(end_string) + end_string.length)
      profile = Plist::parse_xml(profile)

      new(profile)
    end
  end
end
