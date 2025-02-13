"""Custom model extensions and methods"""
from datetime import datetime

# We'll import our models after they're generated
# from .generated import Project, CreditStatement, ContractAward

class ProjectMixin:
    """Custom methods for Project model"""
    def is_active(self):
        return self.approval_date <= datetime.now() <= self.closing_date