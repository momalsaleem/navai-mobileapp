from ultralytics import YOLO

print("Loading YOLOv8n-oiv7 model...")
model = YOLO('yolov8n-oiv7.pt')

print("Exporting model to TFLite format...")
model.export(format='tflite', optimize=False)

print("Export complete!")
