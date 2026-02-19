$ErrorActionPreference = "Stop"

$BUILD_DIR = "build/web"

if (-not (Test-Path $BUILD_DIR)) {
    Write-Error "Build directory $BUILD_DIR does not exist. Please run 'flutter build web' first."
    exit 1
}

# Navigate to build directory
Push-Location $BUILD_DIR

try {
    Write-Host "Initializing git in $BUILD_DIR"
    # Clean up any existing git repo in build dir to start fresh
    if (Test-Path .git) {
        Remove-Item -Recurse -Force .git
    }
    
    git init
    git add .
    git commit -m "Deploy web version (auto-generated)"
    
    # Rename branch to main for consistency
    git branch -M main

    Write-Host "Adding remote"
    # Using the specific repo provided by the user
    git remote add origin https://github.com/Pavankumarswamy/aa.git
    
    Write-Host "Pushing to gh-pages branch"
    # Force push to overwrite history on gh-pages branch
    git push -f origin main:gh-pages
    
    Write-Host "Deployment successful! Your site should be live at https://Pavankumarswamy.github.io/aa/"
}
catch {
    Write-Error "Deployment failed: $_"
}
finally {
    Pop-Location
}
