require 'plist'
require 'securerandom'
require 'fileutils'

module CocoapodsSubmit
  class IPAUploader
    attr_reader :ipa
    attr_reader :bundle_identifier

    def initialize(ipa, bundle_identifier)
      @directory = File.join "/tmp", SecureRandom.uuid
      @ipa = ipa
      @bundle_identifier = bundle_identifier
    end

    def upload
      FileUtils::mkdir_p @directory

      username, password, apple_id = credentials(bundle_identifier)

      transporter = File.join `xcode-select --print-path`.chomp, "/../Applications/Application\\ Loader.app/Contents/MacOS/itms/bin/iTMSTransporter"

      package = create_package(apple_id)
      execute %{#{transporter} -m verify -f "#{package}" -u "#{username}" -p "#{password}"}
      execute %{#{transporter} -m upload -f "#{package}" -u "#{username}" -p "#{password}"}

      `rm -rf "#{@directory}"`
    end

    private
    def create_package(apple_id)
      size = File.size(ipa)
      checksum = Digest::MD5.file(ipa)

      package = File.join @directory, "Package.itmsp"
      FileUtils.mkdir_p(package)

      ipa_path = File.join(package, File.basename(ipa))
      metadata_path = File.join(package, "metadata.xml")

      FileUtils.copy_entry(ipa, ipa_path)
      File.write(metadata_path, metadata(apple_id, checksum, size))

      package
    end

    private
    def execute(command)
      puts "#{"==>".magenta} #{command}"
      abort unless system(command)
    end

    private
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

    private
    def credentials(bundle_identifier)
      username = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.username`.chomp
      return login(bundle_identifier) if $?.to_i > 0

      password = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.password`.chomp
      return login(bundle_identifier) if $?.to_i > 0

      apple_id = `security find-generic-password -wl #{bundle_identifier}.cocoapods-submit.apple-id`.chomp
      return login(bundle_identifier) if $?.to_i > 0

      return [username, password, apple_id]
    end

    private
    def metadata(apple_id, checksum, size)
      %Q(<?xml version="1.0" encoding="UTF-8"?>
<package version="software4.7" xmlns="http://apple.com/itunes/importer">
<software_assets apple_id="#{apple_id}">
  <asset type="bundle">
    <data_file>
      <file_name>#{File.basename ipa}</file_name>
      <checksum type="md5">#{checksum}</checksum>
      <size>#{size}</size>
    </data_file>
  </asset>
</software_assets>
</package>)
    end
  end
end
