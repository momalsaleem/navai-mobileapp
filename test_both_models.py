from ultralytics import YOLO
import sys
import os

print("Starting dual-model detection test (Indoor + Crime Scene)...")

indoor_model_path = 'assets/indoor_objects_model.tflite'
crime_model_path = 'assets/crimescene_detection_best.onnx'

for path in [indoor_model_path, crime_model_path]:
    if not os.path.exists(path):
        print(f"Model file not found: {path}")
        sys.exit(1)

# Load both models
try:
    print("Loading models...")
    indoor_model = YOLO(indoor_model_path, task='detect')
    crime_model = YOLO(crime_model_path, task='detect')
except Exception as e:
    print(f"Error loading models: {e}")
    sys.exit(1)

images_to_test = ['test_blurred_input.jpg', 'test_enhanced_output.jpg']

for img_path in images_to_test:
    print(f"\n{'='*40}")
    print(f"Testing Image: {img_path}")
    print(f"{'='*40}")
    
    if not os.path.exists(img_path):
        print(f"File {img_path} not found.")
        continue
        
    for model_name, model in [("Indoor Objects", indoor_model), ("Crime Scene", crime_model)]:
        print(f"\n--- {model_name} Model Results ---")
        try:
            results = model(img_path)
            
            detected_something = False
            for r in results:
                boxes = r.boxes
                if len(boxes) == 0:
                    continue
                
                detected_something = True
                for box in boxes:
                    cls_idx = int(box.cls[0].item())
                    conf = float(box.conf[0].item())
                    
                    label_name = f"Class {cls_idx}"
                    if model.names and cls_idx in model.names:
                        label_name = model.names[cls_idx]
                        
                    print(f"✅ Detected: {label_name} with confidence {conf*100:.1f}%")
                    
            if not detected_something:
                print("❌ Nothing detected!")
        except Exception as e:
            print(f"Error during inference with {model_name}: {e}")

print("\nDual-model test completed!")
