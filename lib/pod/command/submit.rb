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
        CLAide::Argument.new('target', false),
      ]

      def initialize(argv)
        @target = argv.shift_argument unless argv.arguments.empty?
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

      def run
        workspaces = Dir.entries(".").select { |s| s.end_with? ".xcworkspace" }
        abort "pod submit only supports one .xcworkspace in the current directory" unless workspaces.count == 1

        workspace = Xcodeproj::Workspace.new_from_xcworkspace(workspaces[0])
        project = Xcodeproj::Project.open workspace.file_references.first.path
        schemes = Xcodeproj::Project.schemes project.path

        # TODO: inject build phase to increment build number

        # TODO: choose correct build configuration based on selected provioning profile for AppStore
        targets = project.targets.select { |t| t.product_type == "com.apple.product-type.application" }

        # TODO: abort for multiple application targets
        @target = targets.first.name

        # grap info.plist and extract bundle identifier
        relative_info_path = targets.first.build_configuration_list["Release"].build_settings["INFOPLIST_FILE"]
        info_path = File.join File.dirname(project.path), relative_info_path
        identifier = Plist::parse_xml(info_path)["CFBundleIdentifier"]

        username, password, apple_id = credentials(identifier)

        execute "ipa build --verbose --scheme #{@target} --configuration AppStore | xcpretty -c && exit ${PIPESTATUS[0]}"
        execute "ipa info #{@target}.ipa"

        transporter = File.join `xcode-select --print-path`.chomp, "/../Applications/Application\\ Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"

        create_package(@target, apple_id)
        execute "#{transporter} -m verify -f Package.itmsp -u #{username} -p #{password}"
        execute "#{transporter} -m upload -f Package.itmsp -u #{username} -p #{password}"
        `rm -rf Package.itmsp #{@target}.ipa #{@target}.app.dSYM.zip`
      end

      def metadata(username, checksum, size)
        %Q(<?xml version="1.0" encoding="UTF-8"?>
<package version="software4.7" xmlns="http://apple.com/itunes/importer">
  <software_assets apple_id="#{username}">
    <asset type="bundle">
      <data_file>
        <file_name>#{@target}.ipa</file_name>
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
