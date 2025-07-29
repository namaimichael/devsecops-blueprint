#!/bin/bash

# DevSecOps Blueprint - Ignore Files Setup Script
# This script creates all necessary ignore files with proper placement

set -e

echo "🚀 Setting up ignore files for DevSecOps blueprint..."

# Function to create directory if it doesn't exist
create_dir_if_needed() {
    if [ ! -d "$1" ]; then
        echo "📁 Creating directory: $1"
        mkdir -p "$1"
    fi
}

# 1. ROOT LEVEL FILES
echo "📋 Creating root ignore files..."

# Root .dockerignore (main application builds)
cat > .dockerignore << 'EOF'
# Documentation and metadata
.git
.gitignore
README.md
docs/
*.md

# Infrastructure as Code (shouldn't be in app containers)
bootstrap-backend/
gke-infra/
infra/terraform/
**/.terraform/
*.tfstate*
*.tfvars
*.tf

# Kubernetes manifests (deployed separately)
manifests/

# Security tools (not needed in runtime containers)
security/
*.trivyignore

# Development tools
.vscode/
.idea/
*.swp
.DS_Store

# Logs and temporary files
*.log
logs/
tmp/
temp/

# Build artifacts
target/
build/
dist/

# Dependencies (will be installed in container)
node_modules/
__pycache__/
*.pyc
venv/
.env

# Scripts (use COPY for specific scripts only)
scripts/

# Observability configs (mount as configmaps)
observability/

# CI/CD files
.github/
.gitlab-ci.yml
Jenkinsfile

# Large files
*.zip
*.tar.gz
*.pdf
docs/*.png
EOF

# Root .gcloudignore (GKE deployments)
cat > .gcloudignore << 'EOF'
# Version control
.git/
.gitignore

# Documentation
README.md
docs/
*.md

# Development files
.vscode/
.idea/
*.swp
.DS_Store

# Terraform state (use remote backend)
**/.terraform/
*.tfstate*
tfplan*

# Local development configs
.env
.env.local
venv/
node_modules/

# Security tools output
security/container-scanning/
security/dependency-scanning/
trivy-report.*
dependency-check-report.*
.scannerwork/

# Logs and temporary files
*.log
logs/
tmp/
temp/

# Test files
*_test.py
*_test.go
test_*
tests/

# CI/CD configurations
.github/
.gitlab-ci.yml
Jenkinsfile

# Large files and media
*.zip
*.tar.gz
docs/*.png
observability/
EOF

# Root .trivyignore (global security scanning)
cat > .trivyignore << 'EOF'
# Trivy ignore file - Global exceptions
# Format: CVE-ID (justification)

# Example: Development-only vulnerabilities
# CVE-2023-XXXX (Development dependency, not in production)

# OS-level CVEs that don't affect containerized applications
# Add specific CVEs here with justification

# Note: Keep this file minimal - most ignores should be in specific directories
EOF

echo "✅ Root ignore files created"

# 2. TERRAFORM MODULE FILES
echo "📋 Creating Terraform ignore files..."

# bootstrap-backend/.terraformignore
cat > bootstrap-backend/.terraformignore << 'EOF'
# Git and version control
.git/
.gitignore

# Documentation
README.md
*.md

# IDE files
.vscode/
.idea/
*.swp
.DS_Store

# Local Terraform runtime
.terraform/
terraform.tfstate*
tfplan*

# Example and test files
examples/
tests/
*_test.tf

# CI/CD
.github/
.gitlab-ci.yml

# Other project files
../docs/
../scripts/
../security/
EOF

# gke-infra/.terraformignore
cat > gke-infra/.terraformignore << 'EOF'
# Git and version control
.git/
.gitignore

# Documentation
README.md
*.md

# IDE files
.vscode/
.idea/
*.swp
.DS_Store

# Local Terraform runtime
.terraform/
terraform.tfstate*
tfplan*

# Kubernetes manifests (deployed separately)
manifests/

# Example and test files
examples/
tests/
*_test.tf

# CI/CD
.github/
.gitlab-ci.yml

# Other project directories
../docs/
../scripts/
../security/
../mock-app/
EOF

# infra/terraform/.terraformignore
cat > infra/terraform/.terraformignore << 'EOF'
# Standard Terraform ignores
.git/
.gitignore
README.md
*.md
.vscode/
.idea/
*.swp
.DS_Store
.terraform/
terraform.tfstate*
tfplan*
examples/
tests/
*_test.tf
.github/
.gitlab-ci.yml

# Project-specific
../../docs/
../../scripts/
../../security/
../../mock-app/
../../observability/
EOF

echo "✅ Terraform ignore files created"

# 3. DOCKER-SPECIFIC FILES
echo "📋 Creating Docker ignore files..."

# infra/docker/.dockerignore
cat > infra/docker/.dockerignore << 'EOF'
# Parent directory exclusions
../../.git
../../docs/
../../security/
../../scripts/
../../observability/
../../bootstrap-backend/
../../gke-infra/
../../manifests/

# Development files
.vscode/
.idea/
*.swp
.DS_Store
*.log

# Terraform
**/.terraform/
*.tfstate*
*.tfvars
*.tf

# Build context optimization - only include what's needed for the Docker build
EOF

# mock-app/.dockerignore
cat > mock-app/.dockerignore << 'EOF'
# Git and documentation
.git
README.md
*.md

# Development files
.vscode/
.idea/
*.swp
.DS_Store

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
.pytest_cache/
.coverage
htmlcov/

# Virtual environments
venv/
env/
.env
.venv

# Logs
*.log

# IDE
.idea/
.vscode/

# OS
.DS_Store
Thumbs.db

# Only include app.py and requirements.txt for efficient builds
EOF

echo "✅ Docker ignore files created"

# 4. SECURITY-SPECIFIC FILES
echo "📋 Creating security ignore files..."

# security/.trivyignore
cat > security/.trivyignore << 'EOF'
# Security scanning specific ignores
# More permissive for security tools themselves

# Development tools CVEs (scanning tools, not production apps)
CVE-2023-DEV-*

# Scanner-specific exceptions
# Document each exception with justification
EOF

# security/container-scanning/.trivyignore
cat > security/container-scanning/.trivyignore << 'EOF'
# Container-specific scanning exceptions
# These apply only to container vulnerability scans

# Base image CVEs that are mitigated by runtime security
# CVE-YYYY-XXXX (Mitigated by runtime security controls)

# Scanner false positives
# CVE-YYYY-XXXX (False positive - library not actually vulnerable in our context)
EOF

echo "✅ Security ignore files created"

# 5. SUMMARY
echo ""
echo "🎉 All ignore files created successfully!"
echo ""
echo "📋 Files created:"
echo "   📁 Root level:"
echo "      ├── .gitignore (already exists)"
echo "      ├── .dockerignore"
echo "      ├── .gcloudignore"
echo "      └── .trivyignore"
echo ""
echo "   📁 Terraform modules:"
echo "      ├── bootstrap-backend/.terraformignore"
echo "      ├── gke-infra/.terraformignore"
echo "      └── infra/terraform/.terraformignore"
echo ""
echo "   📁 Docker contexts:"
echo "      ├── infra/docker/.dockerignore"
echo "      └── mock-app/.dockerignore"
echo ""
echo "   📁 Security scanning:"
echo "      ├── security/.trivyignore"
echo "      └── security/container-scanning/.trivyignore"
echo ""
echo "💡 Next steps:"
echo "   1. Review and customize ignore files for your specific needs"
echo "   2. Test Docker builds with new .dockerignore files"
echo "   3. Commit all ignore files to version control"
echo "   4. Update team documentation about ignore file locations"
echo ""
echo "🔐 Security reminder:"
echo "   - Always review .trivyignore exceptions"
echo "   - Document justifications for security exceptions"
echo "   - Regularly audit ignore files for outdated entries"