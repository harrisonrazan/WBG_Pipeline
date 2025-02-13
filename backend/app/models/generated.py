"""Auto-generated models. Do not edit manually."""

from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
from .base import Base

class WbProjectFinancers(Base):
    """SQLAlchemy model for the wb_project_financers table.""" 
    __tablename__ = 'wb_project_financers'

    project = Column('Project', String, primary_key=True)
    name = Column('Name', String)
    current_amount = Column('Current Amount', String)
    amount = Column('Amount (USD)', String)
    financer_id = Column('Financer ID', String, primary_key=True)
    currency = Column('Currency', String)
    project_financial_type = Column('Project Financial Type', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectfinancers_collection',
                               foreign_keys=[project])

    def __repr__(self):
        return f"<WbProjectFinancers({self.project}, {self.financer_id})>"

class WbProjects(Base):
    """SQLAlchemy model for the wb_projects table.""" 
    __tablename__ = 'wb_projects'

    project_id = Column('Project ID', String, primary_key=True)
    region = Column('Region', String)
    country = Column('Country', String)
    project_status = Column('Project Status', String)
    last_stage_reached_name = Column('Last Stage Reached Name', String)
    project_name = Column('Project Name', String)
    project_development_objective = Column('Project Development Objective ', String)
    implementing_agency = Column('Implementing Agency', String)
    public_disclosure_date = Column('Public Disclosure Date', DateTime)
    board_approval_date = Column('Board Approval Date', DateTime)
    loan_effective_date = Column('Loan Effective Date', DateTime)
    project_closing_date = Column('Project Closing Date', DateTime)
    current_project_cost = Column('Current Project Cost', String)
    ibrd_commitment = Column('IBRD Commitment', String)
    ida_commitment = Column('IDA Commitment', String)
    grant_amount = Column('Grant Amount', String)
    total_ibrd_ida_and_grant_commitment = Column('Total IBRD, IDA and Grant Commitment', String)
    borrower = Column('Borrower', String)
    lending_instrument = Column('Lending Instrument', String)
    environmental_assessment_category = Column('Environmental Assessment Category', String)
    environmental_and_social_risk = Column('Environmental and Social Risk', String)
    associated_project = Column('Associated Project', String)
    consultant_services_required = Column('Consultant Services Required', String)
    financing_type = Column('Financing Type', String)

    def __repr__(self):
        return f"<WbProjects({self.project_id})>"

class WbProjectThemes(Base):
    """SQLAlchemy model for the wb_project_themes table.""" 
    __tablename__ = 'wb_project_themes'

    project_id = Column('Project ID', String, primary_key=True)
    level_1 = Column('Level 1', String)
    percentage_1 = Column('Percentage 1', String)
    level_2 = Column('Level 2', String)
    percentage_2 = Column('Percentage 2', String)
    level_3 = Column('Level 3', String)
    percentage_3 = Column('Percentage 3', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectthemes_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectThemes({self.project_id})>"

class WbProjectSectors(Base):
    """SQLAlchemy model for the wb_project_sectors table.""" 
    __tablename__ = 'wb_project_sectors'

    project_id = Column('Project ID', String, primary_key=True)
    major_sector = Column('Major Sector', String)
    sector = Column('Sector', String)
    sector_percent = Column('Sector Percent', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectsectors_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectSectors({self.project_id})>"

class WbProjectGeoLocations(Base):
    """SQLAlchemy model for the wb_project_geo_locations table.""" 
    __tablename__ = 'wb_project_geo_locations'

    project_id = Column('Project ID', String, primary_key=True)
    geo_loc_id = Column('GEO Loc ID', String)
    place_id = Column('Place ID', String)
    wbg_country_key = Column('WBG Country Key', String)
    geo_loc_name = Column('GEO Loc Name', String)
    geo_latitude_number = Column('GEO Latitude Number', String)
    geo_longitude_number = Column('GEO Longitude Number', String)
    admin_unit1_name = Column('Admin Unit1 Name', String)
    admin_unit2_name = Column('Admin Unit2 Name', String)

    # Relationship with the main projects table
    project_rel = relationship('WbProjects', backref='projectgeolocations_collection',
                               foreign_keys=[project_id])

    def __repr__(self):
        return f"<WbProjectGeoLocations({self.project_id})>"

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

