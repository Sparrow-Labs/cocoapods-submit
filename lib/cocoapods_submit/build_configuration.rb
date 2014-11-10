require 'plist'

module CocoapodsSubmit
  class BuildConfiguration
    def initialize(workspace_path, target, configuration)
      output = `xcodebuild -showBuildSettings -workspace "#{workspace_path}" -scheme "#{target.name}" -configuration "#{configuration.name}"`
      abort unless $?

      @hash = {}
      regex = /(\w*) *= *(.*)/
      lines = output.split("\n").select { |s| s.match(regex) }
      lines = lines.map { |s| s.match(regex) }.each { |match| @hash[match[1]] = match[2] }
    end

    def to_s
      super + ": #{@hash.to_s}"
    end

    def [](settings)
      @hash[settings]
    end
  end
end
