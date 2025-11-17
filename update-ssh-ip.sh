#!/bin/bash

# Update SSH config with new external IP after instance restart
# For VS Code + Vertex AI Workbench connection

INSTANCE_NAME="instance-20250827-123722"
ZONE="us-central1-a"
PROJECT="junoplus-dev"
SSH_CONFIG="$HOME/.ssh/config"

echo "🔄 Updating VS Code SSH config with new external IP..."

# Get current external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME \
    --zone=$ZONE \
    --project=$PROJECT \
    --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

if [ -z "$EXTERNAL_IP" ]; then
    echo "❌ Could not get external IP. Make sure the instance is running."
    echo "   Try: gcloud workbench instances start $INSTANCE_NAME --location=$ZONE"
    exit 1
fi

echo "🌍 New external IP: $EXTERNAL_IP"

# Update SSH config
if [ -f "$SSH_CONFIG" ]; then
    # Create backup
    cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

    # Update the HostName line for vertex-workbench
    sed -i '' "/^Host vertex-workbench$/,/^Host / { s/HostName .*/HostName $EXTERNAL_IP/; }" "$SSH_CONFIG"

    echo "✅ SSH config updated successfully"
    echo ""
    echo "🔗 You can now connect with:"
    echo "   • SSH: ssh vertex-workbench"
    echo "   • VS Code: Remote-SSH: Connect to Host → vertex-workbench"
    echo ""
    echo "📝 Updated SSH config:"
    echo "   Host: vertex-workbench"
    echo "   IP: $EXTERNAL_IP"
    echo "   User: jupyter"
else
    echo "❌ SSH config file not found."
    echo "   Please run the VS Code setup first."
    exit 1
fi
