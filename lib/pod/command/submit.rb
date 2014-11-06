module Pod
  class Command
    class Release < Command
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

      def run
        puts "Hallo target: #{@target}"
      end
    end
  end
end
