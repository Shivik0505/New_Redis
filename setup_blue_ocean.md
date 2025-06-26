# Setting up Jenkins Blue Ocean for Redis Infrastructure Project

## 1. Install Blue Ocean Plugin

### Via Jenkins Web Interface:
1. Go to **Manage Jenkins** → **Manage Plugins**
2. Click on **Available** tab
3. Search for "Blue Ocean"
4. Select **Blue Ocean** plugin
5. Click **Install without restart**
6. Wait for installation to complete

### Via Jenkins CLI (Alternative):
```bash
# Download Jenkins CLI
wget http://localhost:8080/jnlpJars/jenkins-cli.jar

# Install Blue Ocean plugin
java -jar jenkins-cli.jar -s http://localhost:8080/ install-plugin blueocean
```

## 2. Access Blue Ocean Dashboard

After installation:
1. Go to Jenkins main dashboard
2. Click **Open Blue Ocean** (blue button on left sidebar)
3. Or navigate directly to: `http://localhost:8080/blue`

## 3. Create Pipeline in Blue Ocean

### Method 1: Import Existing Pipeline
1. In Blue Ocean, click **Create a new Pipeline**
2. Select **GitHub** as source
3. Generate or use existing GitHub token
4. Select your repository: `Shivik0505/New_Redis`
5. Blue Ocean will automatically detect the Jenkinsfile

### Method 2: Use Existing Pipeline
1. Your existing pipeline should appear in Blue Ocean automatically
2. Click on **New_Redis** pipeline to view
3. Blue Ocean will render the visual pipeline based on your Jenkinsfile

## 4. Configure Pipeline for Blue Ocean Optimization

Update your Jenkinsfile to be more Blue Ocean friendly with better stage visualization.
