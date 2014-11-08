require 'plist'

module CocoapodsSubmit
  class ProvisioningProfile
    def self.from_uuid(uuid)
      from_file File.expand_path File.join "~/Library/MobileDevice/Provisioning Profiles", "#{uuid}.mobileprovision"
    end

    def self.from_file(path)
      return nil unless File.exists? path

      start_string = "<?"
      end_string = "</plist>"

      profile = File.read(path)
      profile = profile.slice(profile.index(start_string), profile.length)
      profile = profile.slice(0, profile.index(end_string) + end_string.length)
      profile = Plist::parse_xml(profile)
    end
  end
end
