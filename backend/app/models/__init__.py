# backend/app/models/__init__.py
from .base import Base

# Import generated models (which will be created when the container starts)
try:
    from .generated import *
except ImportError:
    # If models haven't been generated yet, provide placeholder classes
    Project = None
    CreditStatement = None
    ContractAward = None

# Import any custom extensions
from .extensions import *