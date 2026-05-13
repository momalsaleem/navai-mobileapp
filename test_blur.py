import cv2
import numpy as np
import os

print("Starting OpenCV enhancement test using Python...")

image_path = 'assets/chair.png'
if not os.path.exists(image_path):
    print(f"Failed to find {image_path}")
    exit(1)

# 1. Load an original image from assets
original_mat = cv2.imread(image_path, cv2.IMREAD_COLOR)
print(f"Loaded original image: {original_mat.shape[1]}x{original_mat.shape[0]}")

# 2. Create a blurred version to simulate a bad camera frame
blurred_input = cv2.GaussianBlur(original_mat, (15, 15), 5.0, sigmaY=5.0)
cv2.imwrite('test_blurred_input.jpg', blurred_input)
print("Saved test_blurred_input.jpg")

# 3. Apply our enhancement pipeline (Contrast + Unsharp Mask)
# Contrast Adjustment (stronger)
contrast = cv2.convertScaleAbs(blurred_input, alpha=1.5, beta=10.0)

# Sharpening via Unsharp Mask (more aggressive)
blurred_for_mask = cv2.GaussianBlur(contrast, (5, 5), 2.0, sigmaY=2.0)
sharpened = cv2.addWeighted(contrast, 2.5, blurred_for_mask, -1.5, 0.0)

# 4. Save the enhanced result
cv2.imwrite('test_enhanced_output.jpg', sharpened)
print("Saved test_enhanced_output.jpg")
print("Test completed successfully!")
