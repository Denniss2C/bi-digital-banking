# One-off migration that adds the dev/prod flavors to the iOS Xcode project.
#
# Kept in the repo so the project.pbxproj diff is reviewable and reproducible.
# It refuses to run twice. Usage (from apps/banking_app):
#
#   ruby tool/setup_ios_flavors.rb
#
# What it does:
#   1. Replaces Debug/Profile/Release with <Mode>-dev and <Mode>-prod in the
#      project and in every target, copying the original build settings.
#   2. Points each Runner configuration to ios/Flutter/<Mode>-<flavor>.xcconfig,
#      which defines bundle id, display name and APP_FLAVOR per flavor.
#   3. Raises the deployment target to iOS 15 (required by firebase_core 4.x).
#   4. Replaces the bundled GoogleService-Info.plist with a build phase that
#      copies ios/flavors/$(APP_FLAVOR)/GoogleService-Info.plist.
#   5. Replaces the Runner scheme with one scheme per flavor (dev, prod).
require 'fileutils'
require 'xcodeproj'

FLAVORS = %w[dev prod].freeze
MODES = %w[Debug Profile Release].freeze
DEPLOYMENT_TARGET = '15.0'.freeze
COPY_PLIST_PHASE = 'Copy GoogleService-Info.plist for flavor'.freeze

ios_dir = File.expand_path('../ios', __dir__)
project_path = File.join(ios_dir, 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)

if project.build_configurations.any? { |config| config.name == "Debug-#{FLAVORS.first}" }
  abort 'Flavors are already configured; nothing to do.'
end

def deep_copy(settings)
  Marshal.load(Marshal.dump(settings))
end

# The Flutter group has no path of its own (its files use "Flutter/<file>"),
# so references must include the folder.
flutter_group = project.main_group['Flutter']
xcconfig_refs = {}
FLAVORS.each do |flavor|
  flutter_group.new_reference("Flutter/#{flavor}.xcconfig")
  MODES.each do |mode|
    name = "#{mode}-#{flavor}"
    unless File.exist?(File.join(ios_dir, 'Flutter', "#{name}.xcconfig"))
      abort "Missing ios/Flutter/#{name}.xcconfig"
    end
    xcconfig_refs[name] = flutter_group.new_reference("Flutter/#{name}.xcconfig")
  end
end

runner = project.targets.find { |target| target.name == 'Runner' }
lists = [project.build_configuration_list] + project.targets.map(&:build_configuration_list)

# 1-3. Flavored build configurations.
lists.each do |list|
  originals = MODES.map { |mode| [mode, list[mode]] }.to_h
  FLAVORS.each do |flavor|
    MODES.each do |mode|
      source = originals.fetch(mode)
      config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
      config.name = "#{mode}-#{flavor}"
      config.build_settings = deep_copy(source.build_settings)
      config.base_configuration_reference = source.base_configuration_reference

      if list == project.build_configuration_list
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
      end

      if list == runner.build_configuration_list
        # The bundle id now comes from ios/Flutter/<flavor>.xcconfig; a
        # target-level value would override it.
        config.build_settings.delete('PRODUCT_BUNDLE_IDENTIFIER')
        config.base_configuration_reference = xcconfig_refs.fetch(config.name)
      end

      list.build_configurations << config
    end
  end

  originals.each_value do |config|
    list.build_configurations.delete(config)
    config.remove_from_project
  end
  list.default_configuration_name = 'Release-prod'
end

# 4. Per-flavor GoogleService-Info.plist.
old_plist = project.files.find { |file| file.path == 'Runner/GoogleService-Info.plist' }
old_plist&.remove_from_project

phase = runner.new_shell_script_build_phase(COPY_PLIST_PHASE)
phase.shell_script = <<~SH
  # APP_FLAVOR is defined in ios/Flutter/<flavor>.xcconfig.
  cp "${SCRIPT_INPUT_FILE_0}" "${SCRIPT_OUTPUT_FILE_0}"
SH
phase.input_paths = ['$(PROJECT_DIR)/flavors/$(APP_FLAVOR)/GoogleService-Info.plist']
phase.output_paths = ['$(BUILT_PRODUCTS_DIR)/$(PRODUCT_NAME).app/GoogleService-Info.plist']
runner.build_phases.move(phase, runner.build_phases.index(runner.resources_build_phase) + 1)

project.save

# 5. One scheme per flavor, cloned from the default Runner scheme.
schemes_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
runner_scheme = File.join(schemes_dir, 'Runner.xcscheme')
template = File.read(runner_scheme)
FLAVORS.each do |flavor|
  scheme = template.gsub(/buildConfiguration = "(Debug|Profile|Release)"/) do
    %(buildConfiguration = "#{Regexp.last_match(1)}-#{flavor}")
  end
  File.write(File.join(schemes_dir, "#{flavor}.xcscheme"), scheme)
end
FileUtils.rm(runner_scheme)

puts "iOS flavors configured: #{FLAVORS.join(', ')}"
