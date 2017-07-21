# Separate settings file for use in the local (VM) pseudo-production environment
from .settings import *  # noqa

DEBUG = False
ALLOWED_HOSTS = ['*']  # must be set when DEBUG = False

STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.ManifestStaticFilesStorage'

# At main server runtime, this is the path that django presents to clients in its generated HTML output.
STATIC_URL = '/static/'

# This is where django looks for the staticfiles.json manifest file that tells it what
# hash-named file to reference for each source asset.
STATIC_ROOT = os.path.join(BASE_DIR, '..', 'build/static/prod')
