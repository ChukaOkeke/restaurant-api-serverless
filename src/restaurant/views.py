from django.shortcuts import render
from rest_framework import generics, viewsets
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators import api_view, permission_classes
from .models import MenuItem, Booking
from .serializers import MenuSerializer, BookingSerializer

# Create your views here.
# Function-based view to render the homepage to the client
def index(request):
    return render(request, 'index.html', {})

# Class-based view to handle Menu items
class MenuItemsView(generics.ListCreateAPIView):
    queryset = MenuItem.objects.all()  # Fetch all menu items from the database
    serializer_class = MenuSerializer  # Serialize the menu items

# Class-based view to handle a single Menu item
class SingleMenuItemView(generics.RetrieveUpdateAPIView, generics.DestroyAPIView):
    queryset = MenuItem.objects.all()  # Fetch menu item from the database
    serializer_class = MenuSerializer  # Serialize the menu item

# Viewset view to handle Bookings
class BookingViewSet(viewsets.ModelViewSet):
    queryset = Booking.objects.all()  # Fetch all bookings from the database
    serializer_class = BookingSerializer  # Serialize the bookings
    permission_classes = [IsAuthenticated]  # Only authenticated users can access booking endpoints