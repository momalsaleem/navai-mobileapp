import 'dart:io';
import 'package:opencv_dart/opencv_dart.dart' as cv;

void main() {
  print("Starting OpenCV enhancement test...");
  
  try {
    // 1. Load an original image from assets
    final imagePath = 'assets/chair.png';
    final originalMat = cv.imread(imagePath, flags: cv.IMREAD_COLOR);
    if (originalMat.isEmpty) {
      print("Failed to load original image from $imagePath");
      return;
    }
    print("Loaded original image: ${originalMat.cols}x${originalMat.rows}");
    
    // 2. Create a blurred version to simulate a bad camera frame
    final blurredInput = cv.gaussianBlur(originalMat, (15, 15), 5.0, sigmaY: 5.0);
    cv.imwrite('test_blurred_input.jpg', blurredInput);
    print("Saved test_blurred_input.jpg");
    
    // 3. Apply our enhancement pipeline (Contrast + Unsharp Mask)
    // Contrast Adjustment
    final contrast = cv.convertScaleAbs(blurredInput, alpha: 1.2, beta: 5.0);

    // Sharpening via Unsharp Mask
    final blurredForMask = cv.gaussianBlur(contrast, (3, 3), 1.0, sigmaY: 1.0);
    final sharpened = cv.addWeighted(contrast, 1.5, blurredForMask, -0.5, 0.0);
    
    // 4. Save the enhanced result
    cv.imwrite('test_enhanced_output.jpg', sharpened);
    print("Saved test_enhanced_output.jpg");
    
    // Clean up
    originalMat.dispose();
    blurredInput.dispose();
    contrast.dispose();
    blurredForMask.dispose();
    sharpened.dispose();
    
    print("Test completed successfully!");
  } catch (e) {
    print("Error during OpenCV processing: $e");
  }
}
