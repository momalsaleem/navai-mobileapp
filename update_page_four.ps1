# PowerShell script to update page_four.dart

$filePath = "c:\Users\SSC\Documents\momalp\mobileapp\lib\pages\page_four.dart"

# Read the file
$content = Get-Content -Path $filePath -Raw -Encoding UTF8

# Define the pattern to find (using regex to handle special chars)
$oldPattern = [regex]::Escape("    final micStatus = await Permission.microphone.request();") + 
              ".*?" + 
              [regex]::Escape("    }")

# Define the replacement
$newCode = @"
    // Use MicrophoneManager for proper initialization
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
      print('Dashboard: Microphone not ready');
      if (mounted) setState(() => _isListening = false);
      return;
    }
"@

# Try to replace
if ($content -match "final micStatus = await Permission\.microphone\.request\(\);") {
    # Manual replacement - find the section and replace it
    $lines = $content -split "`r`n"
    $newLines = @()
    $skip = $false
    $skipCount = 0
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "final micStatus = await Permission\.microphone\.request\(\);") {
            # Add the new code
            $newLines += "    // Use MicrophoneManager for proper initialization"
            $newLines += "    bool micReady = await MicrophoneManager.initializeMicrophone("
            $newLines += "      speech: _speech,"
            $newLines += "      context: context,"
            $newLines += "      onStatusUpdate: (message) {"
            $newLines += "        if (mounted) {"
            $newLines += "          setState(() => _statusMessage = message);"
            $newLines += "        }"
            $newLines += "      },"
            $newLines += "      isUrdu: Lang.isUrdu,"
            $newLines += "    );"
            $newLines += ""
            $newLines += "    if (!micReady) {"
            $newLines += "      print('Dashboard: Microphone not ready');"
            $newLines += "      if (mounted) setState(() => _isListening = false);"
            $newLines += "      return;"
            $newLines += "    }"
            # Skip the next 5 lines (old code)
            $i += 5
        } else {
            $newLines += $lines[$i]
        }
    }
    
    # Write back
    $newContent = $newLines -join "`r`n"
    Set-Content -Path $filePath -Value $newContent -Encoding UTF8
    Write-Host "SUCCESS: page_four.dart updated!"
} else {
    Write-Host "ERROR: Could not find the pattern"
}
