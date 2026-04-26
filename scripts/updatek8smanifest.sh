#!/bin/bash

set -e

SERVICE_NAME=$1
IMAGE_NAME=$2
TAG=$3

echo "========================================"
echo "Updating YAML for $SERVICE_NAME"
echo "New image: $IMAGE_NAME:$TAG"
echo "========================================"

FILE="$BUILD_SOURCESDIRECTORY/k8s-specifications/${SERVICE_NAME}-deployment.yaml"

echo "Target file: $FILE"

# ✅ Check file exists

if [ ! -f "$FILE" ]; then
echo "ERROR: File not found!"
exit 1
fi

# 🔥 STEP 1: Update YAML image

echo "Updating image in YAML..."
sed -i "s|image: .*${SERVICE_NAME}:.*|image: ${IMAGE_NAME}:${TAG}|g" "$FILE"

echo "Updated image line:"
grep "image:" "$FILE"

# 🔥 STEP 2: Apply to Kubernetes

echo "Applying to Kubernetes..."
kubectl apply -f "$FILE"

echo "========================================"
echo "Kubernetes updated successfully!"
echo "========================================"

# 🔥 STEP 3: Git Sync (FIXED FLOW)

cd $BUILD_SOURCESDIRECTORY

git config user.email "[devops@azure.com](mailto:devops@azure.com)"
git config user.name "azure-pipeline"

echo "Stashing local changes..."
git stash || echo "Nothing to stash"

echo "Pulling latest changes..."
git pull origin main --rebase

echo "Re-applying stashed changes..."
git stash pop || echo "Nothing to pop"

echo "Staging updated file..."
git add k8s-specifications/${SERVICE_NAME}-deployment.yaml

echo "Committing changes..."
git commit -m "[skip ci] Update ${SERVICE_NAME} image to ${TAG}" || echo "No changes to commit"

echo "Pushing to repository..."
git push origin HEAD:main

echo "========================================"
echo "YAML updated + pushed successfully!"
echo "========================================"
