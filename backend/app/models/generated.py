"""Auto-generated models. Do not edit manually."""
import uuid
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean
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
    as_of_date = Column('as_of_date', DateTime)

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
    as_of_date = Column('as_of_date', DateTime)

    def __repr__(self):
        return f"<WbProjectThemes({self.project_id}, {self.level_1}, {self.level_2}, {self.level_3})>"

class WbProjectSectors(Base):
    """SQLAlchemy model for the wb_project_sectors table.""" 
    __tablename__ = 'wb_project_sectors'

    project_id = Column('project_id', String, primary_key=True)
    major_sector = Column('major_sector', String, primary_key=True)
    sector = Column('sector', String, primary_key=True)
    sector_percent = Column('sector_percent', String)
    as_of_date = Column('as_of_date', DateTime)

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
    as_of_date = Column('as_of_date', DateTime)

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
    as_of_date = Column('as_of_date', DateTime)

    def __repr__(self):
        return f"<WbProjectFinancers({self.project}, {self.financer_id})>"

class WbCreditStatements(Base):
    """SQLAlchemy model for the wb_credit_statements table.""" 
    __tablename__ = 'wb_credit_statements'

    agreement_signing_date = Column('agreement_signing_date', String)
    board_approval_date = Column('board_approval_date', String)
    borrower = Column('borrower', String)
    borrowers_obligation_us = Column('borrowers_obligation_us', String)
    cancelled_amount_us = Column('cancelled_amount_us', String)
    closed_date_most_recent = Column('closed_date_most_recent', String)
    country = Column('country', String)
    country_code = Column('country_code', String)
    credit_number = Column('credit_number', String, primary_key=True)
    credit_status = Column('credit_status', String)
    credits_held_us = Column('credits_held_us', String)
    currency_of_commitment = Column('currency_of_commitment', String)
    disbursed_amount_us = Column('disbursed_amount_us', String)
    due_3rd_party_us = Column('due_3rd_party_us', String)
    due_to_ida_us = Column('due_to_ida_us', String)
    effective_date_most_recent = Column('effective_date_most_recent', String)
    end_of_period = Column('end_of_period', String)
    exchange_adjustment_us = Column('exchange_adjustment_us', String)
    first_repayment_date = Column('first_repayment_date', String)
    last_disbursement_date = Column('last_disbursement_date', String)
    last_repayment_date = Column('last_repayment_date', String)
    original_principal_amount_us = Column('original_principal_amount_us', String)
    project_id = Column('project_id', String)
    project_name = Column('project_name', String)
    region = Column('region', String)
    repaid_3rd_party_us = Column('repaid_3rd_party_us', String)
    repaid_to_ida_us = Column('repaid_to_ida_us', String)
    service_charge_rate = Column('service_charge_rate', String)
    sold_3rd_party_us = Column('sold_3rd_party_us', String)
    undisbursed_amount_us = Column('undisbursed_amount_us', String)
    as_of_date = Column('as_of_date', DateTime)

    def __repr__(self):
        return f"<WbCreditStatements({self.credit_number})>"

class WbTrustFundCommitments(Base):
    """SQLAlchemy model for the wb_trust_fund_commitments table.""" 
    __tablename__ = 'wb_trust_fund_commitments'

    execution_type = Column('execution_type', String)
    fiscal_year = Column('fiscal_year', String)
    fund_classification = Column('fund_classification', String)
    new_commitments_us = Column('new_commitments_us', String)
    program_group = Column('program_group', String)
    trust_fund = Column('trust_fund', String)
    trust_fund_name = Column('trust_fund_name', String)
    trust_fund_status = Column('trust_fund_status', String)
    trustee = Column('trustee', String)
    trustee_name = Column('trustee_name', String)
    trustee_status = Column('trustee_status', String)
    as_of_date = Column('as_of_date', DateTime)

    # Synthetic primary key added because none were found
    synthetic_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    def __repr__(self):
        return f"<WbTrustFundCommitments()>"

class WbCorporateProcurementContractAwards(Base):
    """SQLAlchemy model for the wb_corporate_procurement_contract_awards table.""" 
    __tablename__ = 'wb_corporate_procurement_contract_awards'

    award_date = Column('award_date', String)
    commodity_category = Column('commodity_category', String)
    contract_award_amount = Column('contract_award_amount', String)
    contract_description = Column('contract_description', String)
    fund_source = Column('fund_source', String)
    quarter_and_fiscal_year = Column('quarter_and_fiscal_year', String)
    selection_number = Column('selection_number', String)
    supplier = Column('supplier', String)
    supplier_country = Column('supplier_country', String)
    supplier_country_code = Column('supplier_country_code', String)
    vpu_description = Column('vpu_description', String)
    wbg_organization = Column('wbg_organization', String)
    as_of_date = Column('as_of_date', DateTime)

    # Synthetic primary key added because none were found
    synthetic_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    def __repr__(self):
        return f"<WbCorporateProcurementContractAwards()>"

class WbLoanStatements(Base):
    """SQLAlchemy model for the wb_loan_statements table.""" 
    __tablename__ = 'wb_loan_statements'

    agreement_signing_date = Column('agreement_signing_date', String)
    board_approval_date = Column('board_approval_date', String)
    borrower = Column('borrower', String)
    borrowers_obligation = Column('borrowers_obligation', String)
    cancelled_amount = Column('cancelled_amount', String)
    closed_date_most_recent = Column('closed_date_most_recent', String)
    country = Column('country', String)
    country_code = Column('country_code', String)
    currency_of_commitment = Column('currency_of_commitment', String)
    disbursed_amount = Column('disbursed_amount', String)
    due_3rd_party = Column('due_3rd_party', String)
    due_to_ibrd = Column('due_to_ibrd', String)
    effective_date_most_recent = Column('effective_date_most_recent', String)
    end_of_period = Column('end_of_period', String)
    exchange_adjustment = Column('exchange_adjustment', String)
    first_repayment_date = Column('first_repayment_date', String)
    guarantor = Column('guarantor', String)
    guarantor_country_code = Column('guarantor_country_code', String)
    interest_rate = Column('interest_rate', String)
    last_disbursement_date = Column('last_disbursement_date', String)
    last_repayment_date = Column('last_repayment_date', String)
    loan_number = Column('loan_number', String)
    loan_status = Column('loan_status', String)
    loan_type = Column('loan_type', String)
    loans_held = Column('loans_held', String)
    original_principal_amount = Column('original_principal_amount', String)
    project_id = Column('project_id', String)
    project_name = Column('project_name', String)
    region = Column('region', String)
    repaid_3rd_party = Column('repaid_3rd_party', String)
    repaid_to_ibrd = Column('repaid_to_ibrd', String)
    sold_3rd_party = Column('sold_3rd_party', String)
    undisbursed_amount = Column('undisbursed_amount', String)
    as_of_date = Column('as_of_date', DateTime)

    # Synthetic primary key added because none were found
    synthetic_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    def __repr__(self):
        return f"<WbLoanStatements()>"

class WbProcurementNotices(Base):
    """SQLAlchemy model for the wb_procurement_notices table.""" 
    __tablename__ = 'wb_procurement_notices'

    id = Column('id', String)
    url = Column('url', String)
    notice_type = Column('notice_type', String)
    publication_date = Column('publication_date', String)
    project_id = Column('project_id', String)
    bid_description = Column('bid_description', String)
    procurement_category = Column('procurement_category', String)
    procurement_method = Column('procurement_method', String)
    deadline_date = Column('deadline_date', String)
    country_code = Column('country_code', String)
    country_name = Column('country_name', String)
    region = Column('region', String)
    sector = Column('sector', String)
    as_of_date = Column('as_of_date', DateTime)

    # Synthetic primary key added because none were found
    synthetic_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    def __repr__(self):
        return f"<WbProcurementNotices()>"

class WbFinancialIntermediaryFundsContributions(Base):
    """SQLAlchemy model for the wb_financial_intermediary_funds_contributions table.""" 
    __tablename__ = 'wb_financial_intermediary_funds_contributions'

    as_of_date = Column('as_of_date', String)
    fund_name = Column('fund_name', String)
    donor_name = Column('donor_name', String)
    donor_country_code = Column('donor_country_code', String)
    receipt_type = Column('receipt_type', String)
    receipt_quarter = Column('receipt_quarter', String)
    calendar_year = Column('calendar_year', String)
    receipt_currency = Column('receipt_currency', String)
    receipt_amount = Column('receipt_amount', String)
    contribution_type = Column('contribution_type', String)
    sub_account = Column('sub_account', String)
    amount_in_usd = Column('amount_in_usd', String)
    sectortheme = Column('sectortheme', String)

    # Synthetic primary key added because none were found
    synthetic_id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)

    def __repr__(self):
        return f"<WbFinancialIntermediaryFundsContributions()>"

class WbContractAwards(Base):
    """SQLAlchemy model for the wb_contract_awards table.""" 
    __tablename__ = 'wb_contract_awards'

    as_of_date = Column('as_of_date', String)
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
    contract_signing_date = Column('contract_signing_date', String)
    supplier_id = Column('supplier_id', String)
    supplier = Column('supplier', String)
    supplier_country = Column('supplier_country', String)
    supplier_country_code = Column('supplier_country_code', String)
    supplier_contract_amount_usd = Column('supplier_contract_amount_usd', String)
    review_type = Column('review_type', String)

    def __repr__(self):
        return f"<WbContractAwards({self.project_id}, {self.wb_contract_number})>"

