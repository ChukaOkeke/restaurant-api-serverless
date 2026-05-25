import os
import django
from django.core.asgi import get_asgi_application
from mangum import Mangum

# Bootstrapping the Django framework inside the ephemeral container runtime. Point to your native config folder settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

# Instantiating the Asynchronous Server Gateway Interface core
application = get_asgi_application()

# Mangum translates API Gateway proxy events into standard ASGI HTTP contexts
handler = Mangum(application, lifespan="off")