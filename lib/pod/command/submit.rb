require 'plist'
require 'io/console'

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

      def rank_profile(profile)
        return 0.0 unless profile

        rank = 1.0
        rank *= 0.0 if profile["Entitlements"]["get-task-allow"]
        rank *= 1.0 / profile["ProvisionedDevices"].count if profile["ProvisionedDevices"]

        return rank
      end

      def find_app_store_configuration(target)
        best_profile = nil

        identifiers = target.build_configurations.map { |c| c.build_settings["PROVISIONING_PROFILE"] }
        puts identifiers
        return nil

        for configuration in target.build_configurations
          identifier = configuration.build_settings["PROVISIONING_PROFILE"]
          next if identifier.empty?

          path = File.expand_path File.join "~/Library/MobileDevice/Provisioning Profiles", "#{identifier}.mobileprovision"
          next unless File.exists? File.expand_path(path)

          start_string = "<?"
          end_string = "</plist>"

          profile = File.read(path)
          profile = profile.slice(profile.index(start_string), profile.length)
          profile = profile.slice(0, profile.index(end_string) + end_string.length)
          profile = Plist::parse_xml(profile)

          puts "#{configuration.name} => #{path} => #{rank_profile profile}"

          if rank_profile(profile) > rank_profile(best_profile)
            best_profile = profile
          end
        end

        return best_profile
      end

      def run
        workspaces = Dir.entries(".").select { |s| s.end_with? ".xcworkspace" }
        abort "pod submit only supports one .xcworkspace in the current directory" unless workspaces.count == 1

        workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspaces[0])
        project = Xcodeproj::Project.open workspace.file_references.first.path
        schemes = Xcodeproj::Project.schemes project.path

        # TODO: inject build phase to increment build number

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

        configuration = find_app_store_configuration @target

        puts @target.build_configurations[0].class
        exit -1

        # grap info.plist and extract bundle identifier
        relative_info_path = @target.build_configuration_list["Release"].build_settings["INFOPLIST_FILE"]
        info_path = File.join File.dirname(project.path), relative_info_path
        identifier = Plist::parse_xml(info_path)["CFBundleIdentifier"]

        username, password, apple_id = credentials(identifier)

        execute "ipa build --verbose --scheme #{@target_name} --configuration AppStore | xcpretty -c && exit ${PIPESTATUS[0]}"
        execute "ipa info #{@target_name}.ipa"

        transporter = File.join `xcode-select --print-path`.chomp, "/../Applications/Application\\ Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"

        create_package(@target_name, apple_id)
        execute "#{transporter} -m verify -f Package.itmsp -u #{username} -p #{password}"
        execute "#{transporter} -m upload -f Package.itmsp -u #{username} -p #{password}"
        `rm -rf Package.itmsp #{@target_name}.ipa #{@target_name}.app.dSYM.zip`
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
