#!/bin/bash

# GCP Resource Audit Script
# Run this to see what resources actually exist in your GCP project

PROJECT_ID="${1:-credible-bank-466613-j6}"  # Replace with your actual project ID

echo "🔍 GCP Resource Audit for Project: $PROJECT_ID"
echo "=================================================="
echo ""

# Function to check if command succeeded and format output
check_resources() {
    local resource_type="$1"
    local command="$2"
    
    echo "### $resource_type:"
    echo "-------------------"
    
    if eval "$command" 2>/dev/null | tail -n +2 | grep -q .; then
        eval "$command" 2>/dev/null
        echo "❌ Resources found - may need cleanup"
    else
        echo "✅ No $resource_type found"
    fi
    echo ""
}

# Check various GCP resources
check_resources "Compute Engine Instances" \
    "gcloud compute instances list --project=$PROJECT_ID --format='table(name,zone,status,machineType)'"

check_resources "GKE Clusters" \
    "gcloud container clusters list --project=$PROJECT_ID --format='table(name,location,status,currentNodeCount)'"

check_resources "Node Pools" \
    "gcloud container node-pools list --project=$PROJECT_ID --format='table(name,cluster,status,autoscaling.enabled)'"

check_resources "Load Balancers (Forwarding Rules)" \
    "gcloud compute forwarding-rules list --project=$PROJECT_ID --format='table(name,region,IPAddress,target)'"

check_resources "Backend Services" \
    "gcloud compute backend-services list --project=$PROJECT_ID --format='table(name,backends,protocol)'"

check_resources "Target Proxies" \
    "gcloud compute target-http-proxies list --project=$PROJECT_ID --format='table(name,urlMap)'"

check_resources "URL Maps" \
    "gcloud compute url-maps list --project=$PROJECT_ID --format='table(name,defaultService)'"

check_resources "VPC Networks" \
    "gcloud compute networks list --project=$PROJECT_ID --format='table(name,subnet_mode,bgp_routing_mode)'"

check_resources "Subnets" \
    "gcloud compute networks subnets list --project=$PROJECT_ID --format='table(name,region,network,range)'"

check_resources "Firewall Rules" \
    "gcloud compute firewall-rules list --project=$PROJECT_ID --format='table(name,direction,priority,sourceRanges.list():label=SRC_RANGES)'"

check_resources "Static IP Addresses" \
    "gcloud compute addresses list --project=$PROJECT_ID --format='table(name,region,address,status)'"

check_resources "Storage Buckets" \
    "gsutil ls -p $PROJECT_ID"

check_resources "Service Accounts" \
    "gcloud iam service-accounts list --project=$PROJECT_ID --format='table(email,displayName,disabled)'"

check_resources "IAM Policy Bindings (Custom)" \
    "gcloud projects get-iam-policy $PROJECT_ID --format='json' | jq -r '.bindings[] | select(.members[] | contains(\"$PROJECT_ID\")) | .role'"

check_resources "Cloud SQL Instances" \
    "gcloud sql instances list --project=$PROJECT_ID --format='table(name,database_version,region,tier,status)'"

check_resources "Cloud Storage (detailed)" \
    "gsutil ls -L -b gs://*$PROJECT_ID* 2>/dev/null"

check_resources "Persistent Disks" \
    "gcloud compute disks list --project=$PROJECT_ID --format='table(name,zone,sizeGb,type,status)'"

check_resources "Images" \
    "gcloud compute images list --project=$PROJECT_ID --format='table(name,family,status)'"

check_resources "Snapshots" \
    "gcloud compute snapshots list --project=$PROJECT_ID --format='table(name,sourceDisk,status)'"

check_resources "Cloud DNS Zones" \
    "gcloud dns managed-zones list --project=$PROJECT_ID --format='table(name,dnsName,visibility)'"

check_resources "Cloud Functions" \
    "gcloud functions list --project=$PROJECT_ID --format='table(name,status,trigger)'"

check_resources "Cloud Run Services" \
    "gcloud run services list --project=$PROJECT_ID --format='table(name,region,url,lastModifier)'"

check_resources "Pub/Sub Topics" \
    "gcloud pubsub topics list --project=$PROJECT_ID --format='table(name)'"

check_resources "Secrets" \
    "gcloud secrets list --project=$PROJECT_ID --format='table(name,created)'"

echo "🔍 Summary:"
echo "=========="
echo "If any resources show '❌ Resources found', they exist in GCP but are NOT in Terraform state."
echo "These may need manual cleanup or were created outside of Terraform."
echo ""
echo "💡 Next actions:"
echo "1. If resources exist but Terraform shows 'no changes', import them into Terraform state"
echo "2. Or delete them manually using gcloud CLI"
echo "3. Check if resources were created with different naming conventions"