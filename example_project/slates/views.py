from django.views.generic.base import TemplateView


class SlatesListView(TemplateView):
    template_name = 'slates/slates_list.html'
