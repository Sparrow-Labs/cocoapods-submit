require 'plist'
require 'openssl'

module CocoapodsSubmit
  class ProvisioningProfile
    attr_reader :path
    attr_reader :uuid

    def initialize(uuid)
      @uuid = uuid
      @path = File.expand_path File.join "~/Library/MobileDevice/Provisioning Profiles", "#{uuid}.mobileprovision"
      abort "#{@path} not found" unless File.exists? @path

      start_string = "<?"
      end_string = "</plist>"

      profile = File.read(@path)
      profile = profile.slice(profile.index(start_string), profile.length)
      profile = profile.slice(0, profile.index(end_string) + end_string.length)

      @hash = Plist::parse_xml(profile)
      @hash["DeveloperCertificates"] = @hash["DeveloperCertificates"].map { |s| OpenSSL::X509::Certificate.new s.string }
    end

    def signer_identities
      @hash["DeveloperCertificates"].map do |cert|
        array = cert.subject.to_a.flatten
        hash = Hash[array.map.with_index.to_a]

        array[hash["CN"] + 1]
      end
    end

    def[](string)
      @hash[string]
    end

    def rank
      return 0.0 unless @hash

      rank = 1.0
      rank *= 0.0 if @hash["Entitlements"]["get-task-allow"]
      rank *= 1.0 / @hash["ProvisionedDevices"].count if @hash["ProvisionedDevices"]

      return rank
    end

    def to_s
      super + ": #{@hash.to_s}"
    end
  end
end
