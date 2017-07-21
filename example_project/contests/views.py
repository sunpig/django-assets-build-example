from django.views.generic.base import TemplateView


class ContestsListView(TemplateView):
    template_name = 'contests/contests_list.html'
