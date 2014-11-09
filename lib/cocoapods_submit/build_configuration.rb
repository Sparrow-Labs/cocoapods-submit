require 'plist'

module CocoapodsSubmit
  class BuildConfiguration
    def initialize(target)
      output = `xcodebuild -showBuildSettings -project #{target.project.path} -target #{target.name}`
      puts output

      # @hash = hash
    end
  end
end
