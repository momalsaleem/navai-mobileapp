require 'xcodeproj'

project_path = 'd:/momalp/mobileapp/ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.first

# Get the Runner group
runner_group = project.main_group.groups.find { |g| g.name == 'Runner' || g.path == 'Runner' }

# Files to add
files_to_add = [
  'AppInstructionsView.swift',
  'ButtonPressDebouncer.swift',
  'CameraPreview.swift',
  'CameraView.swift',
  'CameraViewModel.swift',
  'DebouncedButton.swift',
  'DetectionOverlayView.swift',
  'DevicePerf.swift',
  'HomeView.swift',
  'LiDARManager.swift',
  'LiveOCRView.swift',
  'LiveOCRViewModel.swift',
  'MemoryManager.swift',
  'MetalImageResizer.swift',
  'ObjectDetectionView.swift',
  'ResourceManager.swift',
  'SettingsOverlayView.swift',
  'SpanishTranslationEngine.swift',
  'SpeechManager.swift',
  'TorchControlView.swift',
  'UIComponents.swift',
  'YOLODetection.swift',
  'YOLOv8Processor.swift',
  'NativeObjectDetectionViewFactory.swift',
  'ContentView.swift'
]

files_to_add.each do |file_name|
  file_path = File.join('Runner', file_name)
  if !runner_group.files.any? { |f| f.path == file_name }
    file_reference = runner_group.new_file(file_name)
    target.add_file_references([file_reference])
    puts "Added #{file_name} to target"
  else
    puts "#{file_name} already exists"
  end
end

# Add class_names.txt as a resource
resources_to_add = [
  'class_names.txt',
  'yolov8n_oiv7.mlpackage'
]

resources_to_add.each do |resource_name|
  if !runner_group.files.any? { |f| f.path == resource_name }
    file_reference = runner_group.new_file(resource_name)
    target.resources_build_phase.add_file_reference(file_reference, true)
    puts "Added #{resource_name} as resource"
  else
    puts "#{resource_name} already exists"
  end
end

# Add Metal file to sources
metal_file = 'Shader.metal'
if !runner_group.files.any? { |f| f.path == metal_file }
  file_reference = runner_group.new_file(metal_file)
  target.source_build_phase.add_file_reference(file_reference, true)
  puts "Added #{metal_file} to sources"
else
  puts "#{metal_file} already exists"
end

project.save
puts "Successfully saved project"
