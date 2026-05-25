import os
import json
import django

# Bootstrap the framework environment for DB engine model visibility
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

def handler(event, context):
    """
    AWS SQS Event Listener execution target.
    Processes messages sent asynchronously from the main API engine.
    """
    for record in event.get('Records', []):
        try:
            # SQS payload body arrives as a stringified JSON string
            message_body = json.loads(record['body'])
            print(f"Processing event message payload task: {message_body}")
            
            # TODO: Add your business background task operations here
            # e.g., Send order verification emails via SES, audit logging, etc.
            
        except Exception as e:
            print(f"Operational execution failure processing queue record: {str(e)}")
            raise e # Raise to keep message in SQS dead-letter queue processing cycle
            
    return {"status": "success", "processed_records": len(event.get('Records', []))}