from django.contrib import admin
from django.urls import path
from autobahnGUI.views import dashboard_view, controlbuttons

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', dashboard_view, name='dashboard'),
    path('controlbuttons/', controlbuttons, name='controlbuttons'),
]
