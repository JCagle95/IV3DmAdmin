from django.urls import path
from django.conf import settings
from django.conf.urls.static import static

from . import views

urlpatterns = [
	path('', views.index),
	path('auth', views.Verification.as_view()),
	path('server', views.ServerInformation.as_view())
]
