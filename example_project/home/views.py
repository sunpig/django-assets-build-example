from django.views.generic.base import TemplateView


class HomeIndexView(TemplateView):
    template_name = 'home/index.html'
