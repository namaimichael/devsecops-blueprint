#!/bin/bash

# Quick Manual Cleanup for credible-bank-466613-j6
# This will delete the expensive resources immediately

PROJECT_ID="credible-bank-466613-j6"

echo "🚨 IMMEDIATE COST-SAVING CLEANUP"
echo "================================"
echo "This will delete the most expensive resources first"
echo ""

# 1. DELETE GKE CLUSTER (HIGHEST COST - Do this first!)
echo "1️⃣ Deleting GKE Cluster (HIGHEST PRIORITY)"
gcloud container clusters delete devsecops-gke-salus \
  --region=us-west1 \
  --project=$PROJECT_ID \
  --quiet

echo "✅ GKE cluster deletion initiated (will take 5-10 minutes)"
echo "💰 This alone will save the most money!"

# 2. Clean up any remaining compute instances
echo ""
echo "2️⃣ Cleaning up remaining compute instances"
gcloud compute instances list --project=$PROJECT_ID --format="value(name,zone)" | \
while IFS=$'\t' read -r name zone; do
  if [[ "$name" == gke-* ]]; then
    echo "🗑️ Deleting compute instance: $name"
    gcloud compute instances delete "$name" --zone="$zone" --project=$PROJECT_ID --quiet
  fi
done

# 3. Clean up GKE-specific firewall rules
echo ""
echo "3️⃣ Cleaning up GKE firewall rules"
gcloud compute firewall-rules list --project=$PROJECT_ID --format="value(name)" | \
grep "gke-devsecops-gke-salus" | \
while read -r rule; do
  echo "🗑️ Deleting firewall rule: $rule"
  gcloud compute firewall-rules delete "$rule" --project=$PROJECT_ID --quiet
done

# 4. Clean up persistent disks (after instances are deleted)
echo ""
echo "4️⃣ Waiting for instances to be deleted before cleaning disks..."
sleep 60

echo "🗑️ Cleaning up orphaned persistent disks"
gcloud compute disks list --project=$PROJECT_ID --format="value(name,zone)" | \
while IFS=$'\t' read -r disk_name zone; do
  if [[ "$disk_name" == gke-* ]] || [[ "$disk_name" == pvc-* ]]; then
    echo "🗑️ Deleting disk: $disk_name"
    gcloud compute disks delete "$disk_name" --zone="$zone" --project=$PROJECT_ID --quiet
  fi
done

# 5. Clean up Cloud Run services
echo ""
echo "5️⃣ Cleaning up Cloud Run services"
gcloud run services delete marine-engine-agent --region=us-central1 --project=$PROJECT_ID --quiet
gcloud run services delete vertex-agent-webhook --region=europe-west1 --project=$PROJECT_ID --quiet

# 6. Clean up Pub/Sub topics
echo ""
echo "6️⃣ Cleaning up Pub/Sub topics"
gcloud pubsub topics delete billing-alerts --project=$PROJECT_ID --quiet

# 7. Clean up Secrets
echo ""
echo "7️⃣ Cleaning up Secrets"
gcloud secrets delete dialogflow-webhook-basic-auth --project=$PROJECT_ID --quiet
gcloud secrets delete vertex-api-key --project=$PROJECT_ID --quiet

# 8. Clean up Terraform state buckets
echo ""
echo "8️⃣ Cleaning up Terraform state buckets"
gsutil rm -r gs://credible-bank-466613-j6-tfstate-dev-cicd
gsutil rm -r gs://credible-bank-466613-j6-tfstate-stage-cicd  
gsutil rm -r gs://credible-bank-466613-j6-tfstate-prod-cicd
gsutil rm -r gs://devsecops-tf-state

# 9. Optional: Clean up other buckets (BE CAREFUL!)
echo ""
echo "9️⃣ Optional bucket cleanup (review contents first!)"
echo "⚠️  Review these buckets before deleting:"
echo "   - gs://credible-bank-466613-j6-manuals/"
echo "   - gs://credible-bank-466613-j6_cloudbuild/"
echo ""
echo "To delete them:"
echo "   gsutil rm -r gs://credible-bank-466613-j6-manuals/"
echo "   gsutil rm -r gs://credible-bank-466613-j6_cloudbuild/"

# 10. Clean up custom service accounts
echo ""
echo "🔟 Cleaning up custom service accounts"
gcloud iam service-accounts delete tf-billing-sa@credible-bank-466613-j6.iam.gserviceaccount.com --project=$PROJECT_ID --quiet
gcloud iam service-accounts delete github-actions-sa@credible-bank-466613-j6.iam.gserviceaccount.com --project=$PROJECT_ID --quiet

echo ""
echo "🎉 CLEANUP COMPLETED!"
echo "===================="
echo "✅ Deleted GKE cluster (biggest cost saver)"
echo "✅ Deleted compute instances and disks"
echo "✅ Deleted Cloud Run services"
echo "✅ Deleted Pub/Sub topics and Secrets"
echo "✅ Deleted Terraform state buckets"
echo "✅ Deleted custom service accounts"
echo ""
echo "💰 COST IMPACT: Major savings achieved!"
echo ""
echo "What was NOT deleted (and that's okay):"
echo "- Default VPC network (free)"
echo "- Default firewall rules (free)"
echo "- Standard GCP images (Google's public images)"
echo "- Default compute service account (required)"
echo ""
echo "🔍 To verify cleanup:"
echo "   gcloud compute instances list --project=$PROJECT_ID"
echo "   gcloud container clusters list --project=$PROJECT_ID"
echo "   gsutil ls -p $PROJECT_ID"