require 'plist'
require 'io/console'
require 'time'

require 'cocoapods_submit/provisioning_profile'
require 'cocoapods_submit/build_configuration'

module Pod
  class Command
    class Submit < Command
      self.summary = 'Build and submit to iTunes Connect'

      def execute(command)
        puts "#{"==>".magenta} #{command}"
        abort unless system(command)
      end

      self.arguments = [
        CLAide::Argument.new('target_name', false),
      ]

      def initialize(argv)
        @target_name = argv.shift_argument unless argv.arguments.empty?
        super
      end

      def login(bundle_identifier)
        puts "You will now have to login to iTunes Connect. Don't worry. Your credentials will be securly stored in your keychain."
        print "Username: "
        username = $stdin.gets.chomp
        abort "Username is required" if username.empty?

        print "Password for #{username}: "
        password = STDIN.noecho(&:gets).chomp
        abort "Password is required" if password.empty?
        puts ""

        print "Apple-ID for #{bundle_identifier} (you can find it in iTunes Connect): "
        apple_id = $stdin.gets.chomp
        abort "Apple-ID is required" if apple_id.empty?

        `security add-generic-password -a #{bundle_identifier}.cocoapods-submit.username -s #{bundle_identifier}.cocoapods-submit.username -w #{username}`
        `security add-generic-password -a #{bundle_identifier}.cocoapods-submit.password -s #{bundle_identifier}.cocoapods-submit.password -w #{password}`
        `security add-generic-password -a #{bundle_identifier}.cocoapods-submit.apple-id -s #{bundle_identifier}.cocoapods-submit.apple-id -w #{apple_id}`

        return [username, password, apple_id]
      end

      def credentials(bundle_identifier)
        username = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.username`.chomp
        return login(bundle_identifier) if $?.to_i > 0

        password = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.password`.chomp
        return login(bundle_identifier) if $?.to_i > 0

        apple_id = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.apple-id`.chomp
        return login(bundle_identifier) if $?.to_i > 0

        return [username, password, apple_id]
      end

      def create_package(target, apple_id)
        ipa = "#{target}.ipa"
        size = File.size(ipa)
        checksum = Digest::MD5.file(ipa)

        FileUtils.mkdir_p("Package.itmsp")
        FileUtils.copy_entry(ipa, "Package.itmsp/#{ipa}")

        File.write("Package.itmsp/metadata.xml", metadata(apple_id, checksum, size))
      end

      def find_best_configuration(target)
        identifiers = target.build_configurations.map { |c| c.build_settings["PROVISIONING_PROFILE"] }
        profiles = identifiers.map { |uuid| CocoapodsSubmit::ProvisioningProfile.new uuid }
        abort "No build configuration for iTunes Connect releases found." if profiles.count == 0

        ranks = profiles.map &:rank
        return target.build_configurations[ranks.each_with_index.max[1]]
      end

      def build(workspace_path, target, configuration)
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

      def run
        workspaces = Dir.entries(".").select { |s| s.end_with? ".xcworkspace" }
        abort "pod submit only supports one .xcworkspace in the current directory" unless workspaces.count == 1

        workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspaces[0])
        project = Xcodeproj::Project.open workspace.file_references.first.path
        schemes = Xcodeproj::Project.schemes project.path

        targets = project.targets.select { |t| t.product_type == "com.apple.product-type.application" }
        if @target_name
          targets = targets.select { |t| t.name == @target_name }
          abort "Target #{@target_name} not found" if targets.count == 0
        end

        if targets.count > 1
          puts "Could not auto determine the target to submit. Please specify your target like:"
          puts ""
          for target in targets
            puts "  * pod submit #{target.name}"
          end
          puts ""
          abort
        end

        @target = targets.first
        @target_name = @target.name

        configuration = find_best_configuration @target
        abort "No build configuration found for target #{@target}." unless configuration

        # grap info.plist and extract bundle identifier
        relative_info_path = @target.build_configuration_list[configuration.name].build_settings["INFOPLIST_FILE"]
        info_path = File.join File.dirname(project.path), relative_info_path
        info_plist = Plist::parse_xml(info_path)
        identifier = info_plist["CFBundleIdentifier"]
        info_plist["CFBundleVersion"] = (info_plist["CFBundleVersion"].to_i + 1).to_s
        File.write info_path, info_plist.to_plist

        username, password, apple_id = credentials(identifier)

        provisioning = CocoapodsSubmit::ProvisioningProfile.new configuration.build_settings["PROVISIONING_PROFILE"]
        abort "cocoapods-submit only supports provisionings with a single signer identity" unless provisioning.signer_identities.count == 1
        signer_identity = provisioning.signer_identities.first

        build_settings = CocoapodsSubmit::BuildConfiguration.new workspaces[0], @target, configuration

        # thanks @mattt: https://github.com/nomad/shenzhen
        app_path = File.join build_settings['BUILT_PRODUCTS_DIR'], build_settings['WRAPPER_NAME']
        frameworks_path = File.join app_path, "Frameworks"
        dsym_path = app_path + ".dSYM"
        ipa_name = build_settings['WRAPPER_NAME'].gsub(build_settings['WRAPPER_SUFFIX'], "") + ".ipa"
        ipa_path = File.expand_path(ipa_name, ".")

        build workspaces[0], @target, configuration
        # execute %{codesign --force --verbose --sign "#{signer_identity}" #{app_path}}
        execute %{codesign --force --verbose --sign "#{signer_identity}" #{frameworks_path}/*} if File.exists? frameworks_path

        execute %{xcrun -sdk iphoneos PackageApplication -v "#{app_path}" -o "#{ipa_path}" --embed "#{dsym_path}" > /dev/null}
        exit -1
        # execute %{xcrun -sdk iphoneos PackageApplication -v "#{app_path}" -o "#{ipa_path}" --embed "#{provisioning.uuid}" --embed "#{dsym_path}" -s "#{signer_identity}" > /dev/null}
        # execute %{xcrun -sdk iphoneos PackageApplication -v "#{app_path}" -o "#{ipa_path}" --embed "#{dsym_path}" > /dev/null}

        transporter = File.join `xcode-select --print-path`.chomp, "/../Applications/Application\\ Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"

        create_package(@target_name, apple_id)
        execute "#{transporter} -m verify -f Package.itmsp -u #{username} -p #{password}"
        execute "#{transporter} -m upload -f Package.itmsp -u #{username} -p #{password}"
        `rm -rf Package.itmsp #{@target_name}.ipa`

        time = Time.now.strftime "%Y%m%d%H%m%S"
        execute "git add ."
        execute "git commit -am 'Submitted to iTunes Connect submit-#{time}-#{@target.name}-#{info_plist["CFBundleShortVersionString"]}-#{info_plist["CFBundleVersion"]}'"
        execute "git tag submit-#{time}-#{@target.name}-#{info_plist["CFBundleShortVersionString"]}-#{info_plist["CFBundleVersion"]}"
        execute "git push && git push --tags"
      end

      def metadata(apple_id, checksum, size)
        %Q(<?xml version="1.0" encoding="UTF-8"?>
<package version="software4.7" xmlns="http://apple.com/itunes/importer">
  <software_assets apple_id="#{apple_id}">
    <asset type="bundle">
      <data_file>
        <file_name>#{@target_name}.ipa</file_name>
        <checksum type="md5">#{checksum}</checksum>
        <size>#{size}</size>
      </data_file>
    </asset>
  </software_assets>
</package>)
      end
    end
  end
end
