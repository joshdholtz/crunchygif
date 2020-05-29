module Fastlane
  module Actions
    class FixSingleTargetSigningAction < Action
      def self.run(params)
        mapping = Actions.lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING]
        specifier = mapping[ENV['MATCH_APP_IDENTIFIER']]
        ENV['GYM_XCARGS'] = "CODE_SIGN_IDENTITY=\"#{params[:code_sign_identity]}\" PROVISIONING_PROFILE_SPECIFIER=\"#{specifier}\""
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
        [
          FastlaneCore::ConfigItem.new(key: :code_sign_identity,
                                       description: "CODE_SIGN_IDENTITY to use")
        ]
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
