#!/bin/bash

echo "🌊 Setting up Jenkins Blue Ocean for Redis Infrastructure Project"

# Check if Jenkins is running
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "❌ Jenkins is not running on localhost:8080"
    echo "Please start Jenkins first:"
    echo "  brew services start jenkins-lts"
    exit 1
fi

echo "✅ Jenkins is running"

# Check if Blue Ocean is installed
echo "🔍 Checking if Blue Ocean plugin is installed..."

# Create Jenkins CLI directory if it doesn't exist
mkdir -p ~/.jenkins-cli

# Download Jenkins CLI if not exists
if [ ! -f ~/.jenkins-cli/jenkins-cli.jar ]; then
    echo "📥 Downloading Jenkins CLI..."
    curl -o ~/.jenkins-cli/jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
fi

# Function to install Blue Ocean plugin
install_blue_ocean() {
    echo "📦 Installing Blue Ocean plugin..."
    java -jar ~/.jenkins-cli/jenkins-cli.jar -s http://localhost:8080/ install-plugin blueocean
    echo "🔄 Restarting Jenkins to activate plugin..."
    java -jar ~/.jenkins-cli/jenkins-cli.jar -s http://localhost:8080/ restart
    echo "⏳ Waiting for Jenkins to restart..."
    sleep 30
}

# Check if Blue Ocean is already installed
if java -jar ~/.jenkins-cli/jenkins-cli.jar -s http://localhost:8080/ list-plugins | grep -q "blueocean"; then
    echo "✅ Blue Ocean plugin is already installed"
else
    install_blue_ocean
fi

echo "🌊 Blue Ocean setup completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Open your browser and go to: http://localhost:8080/blue"
echo "2. Click 'Create a new Pipeline'"
echo "3. Select 'GitHub' as source"
echo "4. Connect your GitHub account"
echo "5. Select repository: Shivik0505/New_Redis"
echo "6. Blue Ocean will automatically detect your Jenkinsfile"
echo ""
echo "🎨 Blue Ocean Features:"
echo "• Visual pipeline editor"
echo "• Real-time pipeline visualization"
echo "• Parallel stage execution view"
echo "• Enhanced logs and artifacts"
echo "• Modern, intuitive interface"
echo ""
echo "🚀 Your Redis Infrastructure Pipeline is ready for Blue Ocean!"
