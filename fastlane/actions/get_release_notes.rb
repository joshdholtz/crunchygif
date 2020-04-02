module Fastlane
  module Actions
    module SharedValues
      GET_RELEASE_NOTES_PATH = :GET_RELEASE_NOTES_PATH
      GET_RELEASE_NOTES_CONTENT = :GET_RELEASE_NOTES_CONTENT
    end

    class GetReleaseNotesAction < Action
      def self.run(params)
        path = params[:path]
        path = File.absolute_path(path)


        unless File.exists?(path)
          UI.user_error!("Release notes do not exist at: #{path}")
        end

        content = File.read(path)

        if params[:review] && !other_action.is_ci?
          UI.message("Release notes: \n#{content}")
          unless UI.confirm("Is this okay?") 
            UI.user_error!("Release nots are not okay!")
          end
        end


        Actions.lane_context[SharedValues::GET_RELEASE_NOTES_PATH] = path
        Actions.lane_context[SharedValues::GET_RELEASE_NOTES_CONTENT] = content

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
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :path,
                                       env_name: "FL_GET_RELEASE_NOTES_PATH",
                                       description: "Path",
                                       default_value: File.join(FastlaneCore::FastlaneFolder.path, "release_notes.txt")),
          FastlaneCore::ConfigItem.new(key: :review,
                                       env_name: "FL_GET_RELEASE_NOTES_SHOULD_REVIEW",
                                       description: "Review before continuing?",
                                       default_value: false,
                                       type: Boolean)
        ]
      end

      def self.output
        [
          ['GET_RELEASE_NOTES_PATH', 'Path'],
          ['GET_RELEASE_NOTES_CONTENT', 'Content']
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
