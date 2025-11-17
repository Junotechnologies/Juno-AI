#!/bin/bash

# Script to run your ML_Training_VertexAI.ipynb notebook on the Vertex AI instance

echo "🚀 Running ML_Training_VertexAI.ipynb on Vertex AI Workbench..."
echo ""

# Connect to instance and run the notebook
ssh vertex-workbench << 'EOF'
echo "📍 Current directory: $(pwd)"
echo "📁 Looking for ML_Training_VertexAI.ipynb..."

# Find the notebook file
NOTEBOOK_PATH=$(find /home/jupyter -name "ML_Training_VertexAI.ipynb" 2>/dev/null | head -1)

if [ -z "$NOTEBOOK_PATH" ]; then
    echo "❌ ML_Training_VertexAI.ipynb not found in /home/jupyter"
    echo "📋 Available .ipynb files:"
    find /home/jupyter -name "*.ipynb" 2>/dev/null | head -10
    exit 1
fi

echo "✅ Found notebook at: $NOTEBOOK_PATH"
echo ""

# Check if jupyter is available
if command -v jupyter &> /dev/null; then
    echo "🔧 Running notebook with jupyter nbconvert..."
    cd "$(dirname "$NOTEBOOK_PATH")"
    jupyter nbconvert --to notebook --execute "$(basename "$NOTEBOOK_PATH")" --output "ML_Training_VertexAI_executed.ipynb"
    echo "✅ Notebook executed! Output saved as ML_Training_VertexAI_executed.ipynb"
else
    echo "⚠️  Jupyter not found in PATH. Using python to run notebook cells..."
    echo "💡 Recommendation: Use VS Code to run the notebook interactively"
fi

EOF

echo ""
echo "🎯 To run interactively with full features:"
echo "1. Connect VS Code to vertex-workbench"
echo "2. Open folder: /home/jupyter"
echo "3. Open ML_Training_VertexAI.ipynb"
echo "4. Run cells with Shift+Enter"
