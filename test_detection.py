from ultralytics import YOLO
import sys
import os

print("Starting YOLO detection test on blurred vs enhanced images...")

model_path = 'assets/indoor_objects_model.tflite'
if not os.path.exists(model_path):
    print(f"Model file not found at {model_path}")
    sys.exit(1)

labels_path = 'assets/labels.txt'
labels = []
if os.path.exists(labels_path):
    with open(labels_path, 'r') as f:
        labels = [line.strip() for line in f.readlines() if line.strip()]

try:
    # Load the TFLite model
    print("Loading TFLite model...")
    model = YOLO(model_path)
    
    images_to_test = ['test_blurred_input.jpg', 'test_enhanced_output.jpg']
    
    for img_path in images_to_test:
        print(f"\n--- Running detection on {img_path} ---")
        if not os.path.exists(img_path):
            print(f"File {img_path} not found.")
            continue
            
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
                
                # Try to get label name
                label_name = f"Class {cls_idx}"
                if cls_idx < len(labels):
                    label_name = labels[cls_idx]
                elif model.names and cls_idx in model.names:
                    label_name = model.names[cls_idx]
                    
                print(f"✅ Detected: {label_name} with confidence {conf*100:.1f}%")
                
        if not detected_something:
            print("❌ Nothing detected!")

except Exception as e:
    print(f"Error during YOLO inference: {e}")

print("\nDetection test completed!")
