from django.contrib import admin
from django.urls import path
from autobahnGUI.views import dashboard_view

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', dashboard_view, name='dashboard'),
]