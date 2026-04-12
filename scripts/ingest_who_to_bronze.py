import sys
import requests
import pandas as pd
from google.cloud import storage
import io


def run_pipeline(indicator, bucket_name):
    print(f"--- Starting Pipeline for {indicator} ---")
    print(bucket_name)
    # 1. Fetch from WHO API
    url = f"https://ghoapi.azureedge.net/api/{indicator}"
    try:
        response = requests.get(url, timeout=30)
        response.raise_for_status()
        data = response.json().get("value", [])
        print(f"Successfully fetched {len(data)} records.")
    except Exception as e:
        print(f"Error fetching data: {e}")
        sys.exit(1)

    # 2. Transform with Pandas
    df = pd.DataFrame(data)
    df["ingestion_timestamp"] = pd.Timestamp.now()
    df["indicator_code"] = indicator

    # 3. Upload directly to GCS (Streaming)
    # This avoids saving a file to the container's disk first
    try:
        client = storage.Client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(f"raw_who_data/{indicator}/data.parquet")

        # Convert DataFrame to Parquet in memory and upload
        buffer = io.BytesIO()
        df.to_parquet(buffer, index=False, engine="pyarrow")
        buffer.seek(0)

        blob.upload_from_file(buffer, content_type="application/octet-stream")
        print(
            f"Successfully uploaded to gs://{bucket_name}/raw_who_data/{indicator}/data.parquet"
        )
    except Exception as e:
        print(f"Error uploading to GCS: {e}")
        sys.exit(1)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python ingest_who_data.py <INDICATOR> <BUCKET_NAME>")
        sys.exit(1)

    run_pipeline(sys.argv[1], sys.argv[2])
