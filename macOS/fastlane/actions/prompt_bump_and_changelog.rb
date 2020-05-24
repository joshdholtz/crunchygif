module Fastlane
  module Actions
    module SharedValues
      PROMPT_BUMP_AND_CHANGELOG_VERSION = :PROMPT_BUMP_AND_CHANGELOG_VERSION
      PROMPT_BUMP_AND_CHANGELOG_BUILD_NUMBER = :PROMPT_BUMP_AND_CHANGELOG_BUILD_NUMBER
      PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_PATH = :PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_PATH
      PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_CONTENT = :PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_CONTENT
    end

    class PromptBumpAndChangelogAction < Action
      def self.run(params)
        xcodeproj_path = params[:xcodeproj] || Dir.glob("*.xcodeproj").first

        # Find target
        require 'xcodeproj'
        xcproj = Xcodeproj::Project.open(xcodeproj_path)
        target = xcproj.targets.find do |t|
          t.name == params[:target]
        end
        UI.user_error!("Could not find target: #{params[:target]}") unless target

        # Get current version and build number
        current_version = target.resolved_build_setting("MARKETING_VERSION", true).values.first
        current_build_number = target.resolved_build_setting("CURRENT_PROJECT_VERSION", true).values.first

        if !params[:read_only]
          # Prompt version
          version = nil
          loop do
            defaulting = current_version.empty? ? "" : " (#{current_version})"
            version = params[:version] || UI.input("Version#{defaulting}?")
            version = current_version if version.empty?    

            break if version && !version.empty?
          end

          # Prompt build number
          build_number = params[:build_number] || UI.input("Build number (defaults to current timestamp)?")
          build_number = Time.now.to_i if build_number.nil? || build_number.empty? 

          # Set version and build number
          target.build_configuration_list.set_setting('MARKETING_VERSION', version)
          target.build_configuration_list.set_setting('CURRENT_PROJECT_VERSION', build_number)
          xcproj.save

          other_action.set_release_notes(path: release_notes_path(version), method: "vim")

          Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_PATH] = Actions.lane_context[SharedValues::SET_RELEASE_NOTES_PATH]
          Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_CONTENT] = Actions.lane_context[SharedValues::SET_RELEASE_NOTES_CONTENT]
        else
          version = current_version
          build_number = current_build_number

          other_action.get_release_notes(path: release_notes_path(version))
          Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_PATH] = Actions.lane_context[SharedValues::GET_RELEASE_NOTES_PATH]
          Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_CONTENT] = Actions.lane_context[SharedValues::GET_RELEASE_NOTES_CONTENT]
        end

        Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_VERSION] = version
        Actions.lane_context[SharedValues::PROMPT_BUMP_AND_CHANGELOG_BUILD_NUMBER] = build_number


        true
      end

      def self.release_notes_path(version_number)
        File.absolute_path("./CHANGELOGS/#{version_number}")
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :xcodeproj,
                                       env_name: "FL_PROMPT_BUMP_AND_CHANGELOG_PROJECT",
                                       description: "Path to the main Xcode project to read version number from, optional. By default will use the first Xcode project found within the project root directory",
                                       optional: true,
                                       verify_block: proc do |value|
                                          UI.user_error!("Please pass the path to the project, not the workspace") if value.end_with?(".xcworkspace")
                                          UI.user_error!("Could not find Xcode project at path '#{File.expand_path(value)}'") if !File.exist?(value) && !Helper.test?
                                       end),
          FastlaneCore::ConfigItem.new(key: :target,
                                       env_name: "FL_PROMPT_BUMP_AND_CHANGELOG_TARGET",
                                       description: "Target to update"),
          FastlaneCore::ConfigItem.new(key: :version,
                                       env_name: "FL_PROMPT_BUMP_AND_CHANGELOG_VERSION",
                                       description: "Version to update",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :build_number,
                                       env_name: "FL_PROMPT_BUMP_AND_CHANGELOG_BUILD_NUMBER",
                                       description: "Build number to update",
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :read_only,
                                       env_name: "FL_PROMPT_BUMP_AND_CHANGELOG_READ_ONLY",
                                       description: "READ_ONLY",
                                       default_value: false,
                                       type: Boolean),
        ]
      end

      def self.output
        [
          ['PROMPT_BUMP_AND_CHANGELOG_VERSION', 'The new version number'],
          ['PROMPT_BUMP_AND_CHANGELOG_BUILD_NUMBER', 'The new build number'],
          ['PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_PATH', 'The changelog path'],
          ['PROMPT_BUMP_AND_CHANGELOG_CHANGELOG_CONTENT', 'The changelog content']
        ]
      end

      def self.return_value
      end

      def self.authors
        ["joshdholtz"]
      end

      def self.is_supported?(platform)
        [:ios, :mac].include?(platform)
      end
    end
  end
end
