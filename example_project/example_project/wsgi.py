"""
WSGI config for example_project project.

It exposes the WSGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/1.11/howto/deployment/wsgi/
"""

import os

import dotenv

from django.core.wsgi import get_wsgi_application

dotenv.read_dotenv('/var/apps/example_project/example_project.env')

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "example_project.settings_local_prod")

application = get_wsgi_application()
