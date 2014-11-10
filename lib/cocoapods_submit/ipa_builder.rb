require 'plist'
require 'securerandom'
require 'fileutils'

module CocoapodsSubmit
  class IPABuilder
    attr_reader :workspace_path
    attr_reader :target
    attr_reader :configuration
    attr_reader :build_settings
    attr_reader :provisioning

    def initialize(workspace_path, target, configuration)
      @directory = File.join "/tmp", SecureRandom.uuid
      @workspace_path = workspace_path
      @target = target
      @configuration = configuration
      @build_settings = BuildConfiguration.new workspace_path, @target, configuration
    end

    def bundle_identifier
      relative_info_path = configuration.build_settings["INFOPLIST_FILE"]
      info_path = File.join File.dirname(@target.project.path), relative_info_path
      Plist::parse_xml(info_path)["CFBundleIdentifier"]
    end

    def build_ipa
      FileUtils.mkdir_p @directory

      increment_bundle_version
      xcodebuild
      copy_app
      # codesign
      ipa_path = package_ipa

      final_ipa_path = File.join ".", File.basename(ipa_path)
      FileUtils.move ipa_path, final_ipa_path

      FileUtils.rm_rf @directory
      final_ipa_path
    end

    private
    def increment_bundle_version
      relative_info_path = configuration.build_settings["INFOPLIST_FILE"]
      info_path = File.join File.dirname(@target.project.path), relative_info_path
      info_plist = Plist::parse_xml(info_path)
      info_plist["CFBundleVersion"] = (info_plist["CFBundleVersion"].to_i + 1).to_s
      File.write info_path, info_plist.to_plist
    end

    private
    def xcodebuild
      flags = []
      flags << %{-sdk iphoneos}
      flags << %{-workspace "#{workspace_path}"}
      flags << %{-scheme "#{target.name}"}
      flags << %{-configuration "#{configuration.name}"}

      actions = []
      actions << :clean
      actions << :build
      actions << :archive

      execute %{xcodebuild #{flags.join(" ")} #{actions.join(" ")} | xcpretty -c && exit ${PIPESTATUS[0]}}
    end

    private
    def execute(command)
      puts "#{"==>".magenta} #{command}"
      abort unless system(command)
    end

    private
    def root_directory
      root_directory = File.join @directory, "root"
      FileUtils.mkdir_p root_directory
      root_directory
    end

    private
    def copy_app
      app_path = File.join build_settings['BUILT_PRODUCTS_DIR'], build_settings['WRAPPER_NAME']
      dsym_path = app_path + ".dSYM"

      FileUtils.cp_r app_path, root_directory
      FileUtils.cp_r dsym_path, root_directory
    end

    private
    def codesign
      provisioning = CocoapodsSubmit::ProvisioningProfile.new configuration.build_settings["PROVISIONING_PROFILE"]
      abort "cocoapods-submit only supports provisionings with a single signer identity" unless provisioning.signer_identities.count == 1
      signer_identity = provisioning.signer_identities.first

      empty_entitlements = entitlements
      app_entitlements = entitlements provisioning["Entitlements"]

      app_path = File.join root_directory, build_settings['WRAPPER_NAME']
      frameworks_path = File.join app_path, "Frameworks"

      execute %{codesign --force --verbose --preserve-metadata=identifier,resource-rules --entitlements "#{empty_entitlements}" --sign "#{signer_identity}" #{frameworks_path}/*} if File.exists? frameworks_path
      execute %{codesign --force --verbose --preserve-metadata=identifier,resource-rules --entitlements "#{app_entitlements}" --sign "#{signer_identity}" #{app_path}}
    end

    private
    def entitlements(entitlements = {})
      entitlements.each do |key, value|
        next unless value.kind_of? Array
        value.delete "Development"
      end

      path = File.join @directory, "#{SecureRandom.uuid}.entitlements"
      File.write path, entitlements.to_plist
      path
    end

    private
    def package_ipa
      app_path = File.join root_directory, build_settings['WRAPPER_NAME']
      dsym_path = app_path + ".dSYM"
      ipa_path = File.join @directory, "#{@target.name}.ipa"

      execute %{xcrun -sdk iphoneos PackageApplication -v "#{app_path}" -o "#{ipa_path}" --embed "#{dsym_path}" > /dev/null}

      ipa_path
    end
  end
end
