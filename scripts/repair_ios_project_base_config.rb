#!/usr/bin/env ruby
# frozen_string_literal: true

project_file =
  if ARGV.empty?
    File.expand_path('../ios/Runner.xcodeproj/project.pbxproj', __dir__)
  else
    File.expand_path(ARGV.first)
  end

abort("Missing Xcode project file: #{project_file}") unless File.exist?(project_file)

contents = File.read(project_file)

project_config_list_match =
  contents.match(
    %r{
      /\* \s Build\ configuration\ list\ for\ PBXProject\ "Runner"\ \*/\ =\ \{
      \s*isa\ =\ XCConfigurationList;
      \s*buildConfigurations\ =\ \(
      \s*([A-Z0-9]{24})\ /\*\ Debug\ \*/,
      \s*([A-Z0-9]{24})\ /\*\ Release\ \*/,
      \s*([A-Z0-9]{24})\ /\*\ Profile\ \*/,
    }mx,
  )

abort('Unable to locate PBXProject "Runner" build configuration list.') if project_config_list_match.nil?

config_ids = {
  'Debug' => project_config_list_match[1],
  'Release' => project_config_list_match[2],
  'Profile' => project_config_list_match[3],
}

def find_file_reference(contents, path)
  lines = contents.lines
  path_line_index = lines.index { |line| line.include?("path = #{path};") }
  abort("Unable to locate file reference for #{path}.") if path_line_index.nil?

  header_index = path_line_index.downto(0).find do |index|
    lines[index].match?(/[A-Z0-9]{24} \/\* .* \*\/ = \{/)
  end
  abort("Unable to locate file reference header for #{path}.") if header_index.nil?

  match = lines[header_index].match(/([A-Z0-9]{24}) \/\* .* \*\/ = \{/)
  abort("Unable to parse file reference id for #{path}.") if match.nil?
  match[1]
end

file_refs = {
  'Debug' => [find_file_reference(contents, 'Flutter/Debug.xcconfig'), 'Debug.xcconfig'],
  'Release' => [find_file_reference(contents, 'Flutter/Release.xcconfig'), 'Release.xcconfig'],
  'Profile' => [find_file_reference(contents, 'Profile.xcconfig'), 'Profile.xcconfig'],
}

updated = contents.dup
changed = false

config_ids.each do |name, config_id|
  file_ref_id, file_comment = file_refs.fetch(name)
  expected_line = "\t\t\tbaseConfigurationReference = #{file_ref_id} /* #{file_comment} */;\n"
  pattern = /
    (\t\t#{config_id}\ \/\*\ #{name}\ \*\/\ =\ \{\n
     \t\t\tisa\ =\ XCBuildConfiguration;\n)
    (\t\t\tbaseConfigurationReference\ =\ [^\n]+\n)?
  /x

  current = updated.match(pattern)
  abort("Unable to locate XCBuildConfiguration block for #{name}.") if current.nil?

  replacement = "#{current[1]}#{expected_line}"
  next if current[0] == replacement

  updated.sub!(pattern, replacement)
  changed = true
end

if changed
  File.write(project_file, updated)
  puts "Repaired project-level Xcode base configurations in #{project_file}"
else
  puts "Project-level Xcode base configurations already match expected xcconfig files."
end
