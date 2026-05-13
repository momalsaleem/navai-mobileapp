import re
import sys

# Set UTF-8 encoding for output
sys.stdout.reconfigure(encoding='utf-8')

# Read the file
with open(r'c:\Users\SSC\Documents\momalp\mobileapp\lib\pages\page_four.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Define the old code to replace (lines 393-398)
old_code = """    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      print('🎤 Microphone permission not granted');
      if (mounted) setState(() => _isListening = false);
      return;
    }"""

# Define the new code
new_code = """    // Use MicrophoneManager for proper initialization
    bool micReady = await MicrophoneManager.initializeMicrophone(
      speech: _speech,
      context: context,
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() => _statusMessage = message);
        }
      },
      isUrdu: Lang.isUrdu,
    );

    if (!micReady) {
      print('❌ Dashboard: Microphone not ready');
      if (mounted) setState(() => _isListening = false);
      return;
    }"""

# Replace the code
if old_code in content:
    content = content.replace(old_code, new_code)
    # Write back
    with open(r'c:\Users\SSC\Documents\momalp\mobileapp\lib\pages\page_four.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: page_four.dart updated!")
else:
    print("ERROR: Could not find the code to replace in page_four.dart")
