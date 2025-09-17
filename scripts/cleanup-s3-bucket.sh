#!/bin/bash
set -e

BUCKET_NAME="filmpro-terraform-state-20240916"

echo "🗑️  Cleaning up S3 bucket: $BUCKET_NAME"

# Delete all object versions
echo "Deleting all object versions..."
aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text | while read key version_id; do
    if [ -n "$key" ] && [ -n "$version_id" ]; then
        echo "Deleting version $version_id of $key"
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id"
    fi
done

# Delete all delete markers
echo "Deleting all delete markers..."
aws s3api list-object-versions --bucket "$BUCKET_NAME" --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text | while read key version_id; do
    if [ -n "$key" ] && [ -n "$version_id" ]; then
        echo "Deleting delete marker $version_id of $key"
        aws s3api delete-object --bucket "$BUCKET_NAME" --key "$key" --version-id "$version_id"
    fi
done

# Delete the bucket
echo "Deleting bucket..."
aws s3 rb "s3://$BUCKET_NAME"

echo "✅ S3 bucket $BUCKET_NAME completely removed"
