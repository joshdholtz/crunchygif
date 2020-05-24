module Fastlane
  module Actions
    module SharedValues
      SET_RELEASE_NOTES_PATH = :SET_RELEASE_NOTES_PATH
      SET_RELEASE_NOTES_CONTENT = :SET_RELEASE_NOTES_CONTENT
    end

    class SetReleaseNotesAction < Action
      def self.run(params)
        path = params[:path]
        path = File.absolute_path(path)

        content = nil
        if File.exists?(path)
          content = File.read(path)
        else
        end


        if params[:show_current]
          if  content
            UI.message("Current release notes: \n#{content}")
          else
            UI.message("Release notes do not exist yet at: #{path}")
          end
        end

        method = params[:method]
        unless method
          method = UI.select("Method?", ["replace", "prepend", "append"])
        end

        if method == "vim"
          system("vim", File.absolute_path(path).shellescape)
          content = File.read(path)
        else
          if params[:notes]
            content = params[:notes]
          else
            loop do
              # Need to add a "\n" here otherwise there will be a new line at the next use of STDIN
              new_content = other_action.prompt(text: "New release notes:", multi_line_end_keyword: "END\n")
              new_content.gsub!("END", "")

              if method == "prepend"
                content = "#{new_content}\n#{content}"
              elsif method == "append"
                content = "#{content}\n#{new_content}"
              else
                content = new_content
              end

              UI.message("New release notes: \n#{content}")
              is_okay = UI.confirm("Is this okay?") 
              if is_okay
                break
              end
            end
          end

          UI.message("Setting new release notes at: #{path}") 
          File.open(path, 'w') { |file| file.write(content) }
        end

        Actions.lane_context[SharedValues::SET_RELEASE_NOTES_PATH] = path
        Actions.lane_context[SharedValues::SET_RELEASE_NOTES_CONTENT] = content

        content
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Get release notes"
      end

      def self.details
        "Get release notes"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_SET_RELEASE_NOTES_PATH",
                                       description: "Path",
                                       default_value: File.join(FastlaneCore::FastlaneFolder.path, "release_notes.txt")),
          FastlaneCore::ConfigItem.new(key: :notes,
                                       env_name: "FL_SET_RELEASE_NOTES_NOTES",
                                       description: "The notes",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :show_current,
                                       env_name: "FL_SET_RELEASE_NOTES_SHOW_CURRENT",
                                       description: "Show current notes?",
                                       default_value: false,
                                       type: Boolean),
          FastlaneCore::ConfigItem.new(key: :method,
                                       env_name: "FL_SET_RELEASE_NOTES_METHOD",
                                       description: "Replace, append, prepend?",
                                       optional: true,
                                       type: String)
        ]
      end

      def self.output
        [
          ['SET_RELEASE_NOTES_PATH', 'Path'],
          ['SET_RELEASE_NOTES_CONTENT', 'Content']
        ]
      end

      def self.return_value
        "Release notes content"
      end

      def self.authors
        ["joshdholtz"]
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
