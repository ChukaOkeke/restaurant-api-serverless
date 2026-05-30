import os
import django
from django.core.asgi import get_asgi_application
from mangum import Mangum

# Bootstrapping the Django framework inside the ephemeral container runtime. Point to your native config folder settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

# Instantiating the Asynchronous Server Gateway Interface core
application = get_asgi_application()

def handler(event, context):
    # Intercept custom operational triggers from your CI/CD pipeline
    if isinstance(event, dict) and event.get("action") == "migrate":
        from django.core.management import call_command
        print("CRITICAL: Migration invocation event captured. Initializing schema sync...")
        try:
            # Executes python manage.py migrate programmatically inside the VPC
            call_command("migrate", no_input=True)
            return {
                "statusCode": 200,
                "body": "Database schema updates compiled successfully."
            }
        except Exception as e:
            print(f"MIGRATION CRASH: {str(e)}")
            return {
                "statusCode": 500,
                "body": f"Migration failed: {str(e)}"
            }

    # Standard inbound API web traffic cascades down to Mangum normally
    asgi_handler = Mangum(application, lifespan="off")
    return asgi_handler(event, context)