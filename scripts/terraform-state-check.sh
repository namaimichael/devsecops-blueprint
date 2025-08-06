#!/bin/bash

# Terraform State Check Script
# This will show what Terraform thinks it's managing

echo "🏗️ Terraform State Analysis"
echo "============================"
echo ""

MODULES=("bootstrap-backend" "gke-infra")
ENVIRONMENTS=("dev" "stage" "prod")

for module in "${MODULES[@]}"; do
    echo "📦 Module: $module"
    echo "=================="
    
    if [ ! -d "$module" ]; then
        echo "❌ Module directory '$module' not found"
        echo ""
        continue
    fi
    
    cd "$module" || continue
    
    # Initialize terraform
    echo "🔧 Initializing Terraform..."
    terraform init -input=false > /dev/null 2>&1
    
    for env in "${ENVIRONMENTS[@]}"; do
        echo ""
        echo "🌍 Environment: $env"
        echo "-------------------"
        
        # Handle workspace for gke-infra
        if [ "$module" = "gke-infra" ]; then
            echo "🔄 Switching to workspace: $env"
            if terraform workspace select "$env" 2>/dev/null; then
                echo "✅ Workspace $env selected"
            else
                echo "❌ Workspace $env doesn't exist"
                continue
            fi
        fi
        
        # Check if tfvars file exists
        if [ ! -f "environments/${env}.tfvars" ]; then
            echo "⚠️ No tfvars file for $env environment"
            continue
        fi
        
        # List resources in state
        echo "📋 Resources in Terraform state:"
        state_resources=$(terraform state list 2>/dev/null)
        
        if [ -n "$state_resources" ]; then
            echo "$state_resources" | while read -r resource; do
                echo "  🔸 $resource"
            done
            
            resource_count=$(echo "$state_resources" | wc -l)
            echo "📊 Total resources: $resource_count"
            
            # Show sample resource details
            echo ""
            echo "📝 Sample resource details:"
            first_resource=$(echo "$state_resources" | head -n 1)
            if [ -n "$first_resource" ]; then
                echo "Details for: $first_resource"
                terraform state show "$first_resource" 2>/dev/null | head -10
            fi
            
        else
            echo "✅ No resources in Terraform state for $env"
        fi
        
        echo ""
        echo "🔍 Checking for drift (plan):"
        terraform plan -var-file="environments/${env}.tfvars" -input=false -detailed-exitcode > /dev/null 2>&1
        plan_exit_code=$?
        
        case $plan_exit_code in
            0)
                echo "✅ No changes needed - state matches reality"
                ;;
            1)
                echo "❌ Terraform plan failed - check configuration"
                ;;
            2)
                echo "⚠️ Changes detected - state doesn't match reality"
                echo "Running plan to see differences:"
                terraform plan -var-file="environments/${env}.tfvars" -input=false -no-color 2>/dev/null | head -20
                ;;
        esac
        
        echo "----------------------------------------"
    done
    
    # Reset workspace to default for gke-infra
    if [ "$module" = "gke-infra" ]; then
        terraform workspace select default > /dev/null 2>&1
    fi
    
    cd ..
    echo ""
done

echo ""
echo "🎯 Summary & Recommendations:"
echo "=============================="
echo ""
echo "If you see:"
echo "✅ 'No resources in state' + 'No changes needed' = Everything is clean"
echo "⚠️ 'Resources in state' + 'No changes needed' = Resources exist and are managed"
echo "❌ 'Resources in state' + 'Changes detected' = State drift - resources may exist outside Terraform"
echo ""
echo "💡 Next steps:"
echo "1. If resources exist in GCP but not in Terraform state - import them or delete manually"
echo "2. If resources exist in both - run the destroy pipeline with dry_run=false"
echo "3. If no resources anywhere - you're already clean!"