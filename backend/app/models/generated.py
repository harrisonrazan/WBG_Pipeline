"""Auto-generated models. Do not edit manually."""

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base

class WbProjects(Base):
    """SQLAlchemy model for the wb_projects table.""" 
    __tablename__ = 'wb_projects'

    project_id = Column('project_id', String, primary_key=True)
    region = Column('region', String)
    country = Column('country', String)
    project_status = Column('project_status', String)
    last_stage_reached_name = Column('last_stage_reached_name', String)
    project_name = Column('project_name', String)
    project_development_objective = Column('project_development_objective', String)
    implementing_agency = Column('implementing_agency', String)
    public_disclosure_date = Column('public_disclosure_date', DateTime)
    board_approval_date = Column('board_approval_date', DateTime)
    loan_effective_date = Column('loan_effective_date', DateTime)
    project_closing_date = Column('project_closing_date', DateTime)
    current_project_cost = Column('current_project_cost', String)
    ibrd_commitment = Column('ibrd_commitment', String)
    ida_commitment = Column('ida_commitment', String)
    grant_amount = Column('grant_amount', String)
    total_ibrd_ida_and_grant_commitment = Column('total_ibrd_ida_and_grant_commitment', String)
    borrower = Column('borrower', String)
    lending_instrument = Column('lending_instrument', String)
    environmental_assessment_category = Column('environmental_assessment_category', String)
    environmental_and_social_risk = Column('environmental_and_social_risk', String)
    associated_project = Column('associated_project', String)
    consultant_services_required = Column('consultant_services_required', String)
    financing_type = Column('financing_type', String)

    def __repr__(self):
        return f"<WbProjects({self.project_id})>"

class WbProjectThemes(Base):
    """SQLAlchemy model for the wb_project_themes table.""" 
    __tablename__ = 'wb_project_themes'

    project_id = Column('project_id', String, primary_key=True)
    level_1 = Column('level_1', String, primary_key=True)
    percentage_1 = Column('percentage_1', String)
    level_2 = Column('level_2', String, primary_key=True)
    percentage_2 = Column('percentage_2', String)
    level_3 = Column('level_3', String, primary_key=True)
    percentage_3 = Column('percentage_3', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectthemes_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectThemes({self.project_id}, {self.level_1}, {self.level_2}, {self.level_3})>"

class WbProjectSectors(Base):
    """SQLAlchemy model for the wb_project_sectors table.""" 
    __tablename__ = 'wb_project_sectors'

    project_id = Column('project_id', String, primary_key=True)
    major_sector = Column('major_sector', String, primary_key=True)
    sector = Column('sector', String, primary_key=True)
    sector_percent = Column('sector_percent', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectsectors_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectSectors({self.project_id}, {self.major_sector}, {self.sector})>"

class WbProjectGeoLocations(Base):
    """SQLAlchemy model for the wb_project_geo_locations table.""" 
    __tablename__ = 'wb_project_geo_locations'

    project_id = Column('project_id', String, primary_key=True)
    geo_loc_id = Column('geo_loc_id', String, primary_key=True)
    place_id = Column('place_id', String, primary_key=True)
    wbg_country_key = Column('wbg_country_key', String)
    geo_loc_name = Column('geo_loc_name', String)
    geo_latitude_number = Column('geo_latitude_number', String)
    geo_longitude_number = Column('geo_longitude_number', String)
    admin_unit1_name = Column('admin_unit1_name', String)
    admin_unit2_name = Column('admin_unit2_name', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectgeolocations_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectGeoLocations({self.project_id}, {self.geo_loc_id}, {self.place_id})>"

class WbProjectFinancers(Base):
    """SQLAlchemy model for the wb_project_financers table.""" 
    __tablename__ = 'wb_project_financers'

    project = Column('project', String, primary_key=True)
    name = Column('name', String)
    current_amount = Column('current_amount', String)
    amount_usd = Column('amount_usd', String)
    financer_id = Column('financer_id', String, primary_key=True)
    currency = Column('currency', String)
    project_financial_type = Column('project_financial_type', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectfinancers_collection',
                               foreign_keys=[project])

    def __repr__(self):
        return f"<WbProjectFinancers({self.project}, {self.financer_id})>"

class WbCreditStatements(Base):
    """SQLAlchemy model for the wb_credit_statements table.""" 
    __tablename__ = 'wb_credit_statements'

    agreement_signing_date = Column('agreement_signing_date', DateTime)
    board_approval_date = Column('board_approval_date', DateTime)
    borrower = Column('borrower', String)
    borrowers_obligation_us = Column('borrowers_obligation_us_', String)
    cancelled_amount_us = Column('cancelled_amount_us_', String)
    closed_date_most_recent = Column('closed_date_most_recent', DateTime)
    country = Column('country', String)
    country_code = Column('country_code', String)
    credit_number = Column('credit_number', String, primary_key=True)
    credit_status = Column('credit_status', String)
    credits_held_us = Column('credits_held_us_', String)
    currency_of_commitment = Column('currency_of_commitment', String)
    disbursed_amount_us = Column('disbursed_amount_us_', String)
    due_3rd_party_us = Column('due_3rd_party_us_', String)
    due_to_ida_us = Column('due_to_ida_us_', String)
    effective_date_most_recent = Column('effective_date_most_recent', DateTime)
    end_of_period = Column('end_of_period', DateTime)
    exchange_adjustment_us = Column('exchange_adjustment_us_', String)
    first_repayment_date = Column('first_repayment_date', DateTime)
    last_disbursement_date = Column('last_disbursement_date', DateTime)
    last_repayment_date = Column('last_repayment_date', DateTime)
    original_principal_amount_us = Column('original_principal_amount_us_', String)
    project_id = Column('project_id', String)
    project_name = Column('project_name', String)
    region = Column('region', String)
    repaid_3rd_party_us = Column('repaid_3rd_party_us_', String)
    repaid_to_ida_us = Column('repaid_to_ida_us_', String)
    service_charge_rate = Column('service_charge_rate', String)
    sold_3rd_party_us = Column('sold_3rd_party_us_', String)
    undisbursed_amount_us = Column('undisbursed_amount_us_', String)
    total_repayment = Column('total_repayment', String)
    repayment_rate = Column('repayment_rate', String)
    processed_at = Column('processed_at', DateTime)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='creditstatements_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbCreditStatements({self.credit_number})>"

class WbContractAwards(Base):
    """SQLAlchemy model for the wb_contract_awards table.""" 
    __tablename__ = 'wb_contract_awards'

    as_of_date = Column('as_of_date', DateTime)
    fiscal_year = Column('fiscal_year', String)
    region = Column('region', String)
    borrower_country = Column('borrower_country', String)
    borrower_country_code = Column('borrower_country_code', String)
    project_id = Column('project_id', String, primary_key=True)
    project_name = Column('project_name', String)
    project_global_practice = Column('project_global_practice', String)
    procurement_category = Column('procurement_category', String)
    procurement_method = Column('procurement_method', String)
    wb_contract_number = Column('wb_contract_number', String, primary_key=True)
    contract_description = Column('contract_description', String)
    borrower_contract_reference_number = Column('borrower_contract_reference_number', String)
    contract_signing_date = Column('contract_signing_date', DateTime)
    supplier_id = Column('supplier_id', String)
    supplier = Column('supplier', String)
    supplier_country = Column('supplier_country', String)
    supplier_country_code = Column('supplier_country_code', String)
    supplier_contract_amount_usd = Column('supplier_contract_amount_usd', String)
    review_type = Column('review_type', String)
    is_domestic_supplier = Column('is_domestic_supplier', Boolean)
    contract_age_days = Column('contract_age_days', String)
    processed_at = Column('processed_at', DateTime)
    fiscal_quarter = Column('fiscal_quarter', Integer)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='contractawards_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbContractAwards({self.project_id}, {self.wb_contract_number})>"

