#!/bin/bash

# Deploy AWS Accounts Factory
# This script helps deploy the AWS Organization and accounts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        exit 1
    fi
    
    # Check if Terragrunt is installed
    if ! command -v terragrunt &> /dev/null; then
        print_error "Terragrunt is not installed. Please install it first."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_success "All prerequisites are met."
}

# Validate AWS permissions
validate_permissions() {
    print_status "Validating AWS permissions..."
    
    # Check if user has Organizations permissions
    if ! aws organizations describe-organization &> /dev/null; then
        print_warning "Unable to describe organization. This might be the first time running Organizations."
        print_warning "Ensure you have OrganizationsFullAccess permissions."
    fi
    
    # Get current AWS account ID
    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    print_status "Current AWS Account ID: $ACCOUNT_ID"
    
    # Check if account is in an organization
    if aws organizations describe-organization &> /dev/null; then
        ORG_ID=$(aws organizations describe-organization --query Organization.Id --output text)
        print_status "Organization ID: $ORG_ID"
    else
        print_status "No organization exists. Will create new organization."
    fi
}

# Prompt for email addresses
get_email_addresses() {
    print_status "Setting up email addresses for accounts..."
    
    # Default email domain
    read -p "Enter your email domain (e.g., example.com): " EMAIL_DOMAIN
    
    if [[ -z "$EMAIL_DOMAIN" ]]; then
        print_error "Email domain is required."
        exit 1
    fi
    
    # Construct email addresses
    MASTER_EMAIL="luciowl-master@${EMAIL_DOMAIN}"
    SHARED_EMAIL="luciowl+shared@${EMAIL_DOMAIN}"
    DEV_NETWORK_EMAIL="luciowl+dev-network@${EMAIL_DOMAIN}"
    DEV_WORKLOADS_EMAIL="luciowl+dev-workloads@${EMAIL_DOMAIN}"
    
    print_status "Will use the following email addresses:"
    echo "  Master: $MASTER_EMAIL"
    echo "  Shared: $SHARED_EMAIL"
    echo "  Dev-Network: $DEV_NETWORK_EMAIL"
    echo "  Dev-Workloads: $DEV_WORKLOADS_EMAIL"
    
    read -p "Are these correct? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Please update the email addresses manually in the Terragrunt configuration."
        exit 1
    fi
}

# Update Terragrunt configuration with email addresses
update_terragrunt_config() {
    print_status "Updating Terragrunt configuration..."
    
    CONFIG_FILE="infra/live/organization/accounts-factory/terragrunt.hcl"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Terragrunt configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Backup original file
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup"
    
    # Update email addresses
    sed -i.tmp "s/your-master-account@example.com/$MASTER_EMAIL/g" "$CONFIG_FILE"
    sed -i.tmp "s/luciowl+shared@example.com/$SHARED_EMAIL/g" "$CONFIG_FILE"
    sed -i.tmp "s/luciowl+dev-network@example.com/$DEV_NETWORK_EMAIL/g" "$CONFIG_FILE"
    sed -i.tmp "s/luciowl+dev-workloads@example.com/$DEV_WORKLOADS_EMAIL/g" "$CONFIG_FILE"
    
    # Clean up temporary file
    rm "$CONFIG_FILE.tmp"
    
    print_success "Terragrunt configuration updated."
}

# Deploy the accounts factory
deploy_accounts_factory() {
    print_status "Deploying AWS Accounts Factory..."
    
    # Navigate to the accounts factory directory
    cd infra/live/organization/accounts-factory
    
    # Initialize Terragrunt
    print_status "Initializing Terragrunt..."
    terragrunt init
    
    # Plan deployment
    print_status "Planning deployment..."
    terragrunt plan
    
    # Ask for confirmation
    print_warning "This will create AWS accounts and organization structure."
    read -p "Do you want to proceed with deployment? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_error "Deployment cancelled."
        exit 1
    fi
    
    # Apply deployment
    print_status "Applying deployment..."
    terragrunt apply
    
    # Navigate back to root
    cd ../../../../
    
    print_success "AWS Accounts Factory deployed successfully!"
}

# Verify deployment
verify_deployment() {
    print_status "Verifying deployment..."
    
    # List all accounts
    print_status "Listing all accounts:"
    aws organizations list-accounts --query 'Accounts[*].[Name,Id,Email]' --output table
    
    # List organizational units
    ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)
    print_status "Listing organizational units:"
    aws organizations list-organizational-units-for-parent --parent-id "$ROOT_ID" --query 'OrganizationalUnits[*].[Name,Id]' --output table
    
    print_success "Deployment verification complete."
}

# Display next steps
show_next_steps() {
    print_status "Next Steps:"
    echo ""
    echo "1. Configure AWS profiles for each account:"
    echo "   aws configure set profile.shared.role_arn arn:aws:iam::SHARED-ACCOUNT-ID:role/OrganizationAccountAccessRole"
    echo "   aws configure set profile.dev-network.role_arn arn:aws:iam::DEV-NETWORK-ACCOUNT-ID:role/OrganizationAccountAccessRole"
    echo "   aws configure set profile.dev-workloads.role_arn arn:aws:iam::DEV-WORKLOADS-ACCOUNT-ID:role/OrganizationAccountAccessRole"
    echo ""
    echo "2. Deploy shared resources:"
    echo "   cd infra/live/shared/ecr && terragrunt apply"
    echo "   cd infra/live/shared/s3 && terragrunt apply"
    echo ""
    echo "3. Deploy networking infrastructure:"
    echo "   cd infra/live/dev/network && terragrunt apply"
    echo ""
    echo "4. Deploy workloads:"
    echo "   cd infra/live/dev/workloads/postgres && terragrunt apply"
    echo "   cd infra/live/dev/workloads/backend && terragrunt apply"
    echo "   cd infra/live/dev/workloads/frontend && terragrunt apply"
    echo "   cd infra/live/dev/workloads/pipeline && terragrunt apply"
    echo ""
    echo "For detailed instructions, see: infra/live/organization/README.md"
}

# Main execution
main() {
    print_status "Starting AWS Accounts Factory deployment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Validate permissions
    validate_permissions
    
    # Get email addresses
    get_email_addresses
    
    # Update configuration
    update_terragrunt_config
    
    # Deploy accounts factory
    deploy_accounts_factory
    
    # Verify deployment
    verify_deployment
    
    # Show next steps
    show_next_steps
    
    print_success "AWS Accounts Factory deployment completed successfully!"
}

# Handle script interruption
trap 'print_error "Script interrupted. Cleaning up..."; exit 1' INT TERM

# Run main function
main "$@" 