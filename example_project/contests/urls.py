from django.conf.urls import url

from . import views

urlpatterns = [
    url(r'^list$', views.ContestsListView.as_view(), name='contests_list'),
]
