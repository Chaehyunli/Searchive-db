#!/bin/sh

# 스크립트 실행 중 오류가 발생하면 즉시 중단
set -e

# --- 설정 변수 ---
MINIO_ALIAS="local"
MINIO_BUCKET="user-documents"
MINIO_URL="http://minio:9000"

# --- 스크립트 시작 ---

# 1. MinIO 서버가 준비될 때까지 접속 재시도 (동적 대기)
echo "Waiting for MinIO service at ${MINIO_URL}..."
until mc alias set ${MINIO_ALIAS} ${MINIO_URL} ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}; do
    echo "MinIO not ready yet, retrying in 5 seconds..."
    sleep 5
done
echo "✅ MinIO client configured successfully."

# 2. 버킷 생성
echo "Checking for bucket '${MINIO_BUCKET}'..."
if mc ls "${MINIO_ALIAS}/${MINIO_BUCKET}" > /dev/null 2>&1; then
    echo "✔️ Bucket '${MINIO_BUCKET}' already exists."
else
    echo "Creating bucket '${MINIO_BUCKET}'..."
    mc mb "${MINIO_ALIAS}/${MINIO_BUCKET}"
    echo "✅ Bucket '${MINIO_BUCKET}' created."
fi

# 3. 버킷 정책 설정 (비공개)
echo "Setting bucket policy for '${MINIO_BUCKET}' to private..."
mc anonymous set none "${MINIO_ALIAS}/${MINIO_BUCKET}"
echo "✅ Bucket policy set successfully."

# 4. 최종 확인
echo "----------------------------------------"
echo "MinIO initialization complete."
echo "Current buckets list:"
mc ls ${MINIO_ALIAS}
echo "----------------------------------------"

exit 0