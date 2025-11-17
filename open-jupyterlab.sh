#!/bin/bash

# Open JupyterLab in browser with authentication
echo "🚀 Opening Vertex AI Workbench JupyterLab..."
echo "📍 Instance: instance-20250827-123722"
echo "🌐 This will open JupyterLab in your default browser"
echo ""

# The proxy URL from the instance description
PROXY_URL="https://da7c13cb93608dc-dot-us-central1.notebooks.googleusercontent.com"

echo "Opening JupyterLab at: $PROXY_URL"
echo ""
echo "Note: You'll need to authenticate with your Google account"
echo "This is faster than the Google Cloud Console interface"

# Open the URL in the default browser
open "$PROXY_URL"

echo "✅ JupyterLab should now be opening in your browser"
echo ""
echo "💡 Tips:"
echo "- This bypasses the slow Google Cloud Console"
echo "- You can bookmark this URL for quick access"
echo "- All your notebooks and data are on the remote instance"
echo "- Use the terminal in JupyterLab for command-line access"
