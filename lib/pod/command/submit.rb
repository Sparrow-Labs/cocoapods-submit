require 'plist'
require 'io/console'
require 'time'
require 'cocoapods_submit'

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

      def find_best_configuration(target)
        identifiers = target.build_configurations.map { |c| c.build_settings["PROVISIONING_PROFILE"] }
        profiles = identifiers.map { |uuid| CocoapodsSubmit::ProvisioningProfile.new uuid }
        abort "No build configuration for iTunes Connect releases found." if profiles.count == 0

        ranks = profiles.map &:rank
        return target.build_configurations[ranks.each_with_index.max[1]]
      end

      def tag_release
        time = Time.now.strftime "%Y%m%d%H%m%S"
        execute "git add ."
        execute "git commit -am 'Submitted to iTunes Connect submit-#{time}-#{@target.name}-#{info_plist["CFBundleShortVersionString"]}-#{info_plist["CFBundleVersion"]}'"
        execute "git tag submit-#{time}-#{@target.name}-#{info_plist["CFBundleShortVersionString"]}-#{info_plist["CFBundleVersion"]}"
        execute "git push && git push --tags"
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

        ipa_builder = CocoapodsSubmit::IPABuilder.new workspaces[0], targets.first, configuration
        path = ipa_builder.build_ipa

        uploader = CocoapodsSubmit::IPAUploader.new path, ipa_builder.bundle_identifier
        uploader.upload

        ipa_builder.cleanup
        tag_release
      end
    end
  end
end
