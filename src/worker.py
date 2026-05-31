import os
import json
import boto3
import django

# Bootstrap the framework environment for DB engine model visibility
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

# Models must be imported AFTER django.setup() is called
from restaurant.models import Booking

def send_confirmation_email(booking_name, guests, date):
    """Dispatches an email notification via AWS SES."""
    ses_client = boto3.client('ses', region_name=os.getenv('AWS_REGION', 'eu-west-1'))
    
    # Both of these emails MUST be verified in the AWS SES Console sandbox
    sender = "okekechuka96@gmail.com" 
    recipient = "success@simulator.amazonses.com"  # SES test recipient that simulates successful email delivery
    
    subject = f"New Booking Confirmed: {booking_name}"
    body_text = f"A new booking has been created via the serverless async queue.\n\nName: {booking_name}\nGuests: {guests}\nDate: {date}"
    
    try:
        ses_client.send_email(
            Source=sender,
            Destination={'ToAddresses': [recipient]},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body_text}}
            }
        )
        print(f"SES notification dispatched for: {booking_name}")
    except Exception as e:
        print(f"SES Error: Failed to send email. {str(e)}")

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
            
            # 1. Write the payload to the Aurora Serverless Database
            booking = Booking.objects.create(
                name=message_body['name'],
                no_of_guests=message_body['no_of_guests'],
                booking_date=message_body['booking_date']
            )
            print(f"Successfully saved booking ID: {booking.id}")
            
            # 2. Execute the downstream email notification
            send_confirmation_email(
                message_body['name'], 
                message_body['no_of_guests'], 
                message_body['booking_date']
            )
            
        except Exception as e:
            print(f"Operational execution failure processing queue record: {str(e)}")
            raise e # Raise to keep message in SQS dead-letter queue processing cycle
            
    return {"status": "success", "processed_records": len(event.get('Records', []))}