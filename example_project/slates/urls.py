from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^list$', views.SlatesListView.as_view(), name='slates_list'),
]
