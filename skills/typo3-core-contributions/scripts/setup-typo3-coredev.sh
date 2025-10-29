#!/bin/bash
# TYPO3 Core Development Environment Setup Script
# Based on proven production workflow
# Creates complete DDEV-based TYPO3 Core development environment

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_step() {
    echo -e "${GREEN}➜${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"

    local missing_prereqs=false

    # Check Git
    if command -v git &> /dev/null; then
        print_success "Git: $(git --version)"
    else
        print_error "Git not found. Please install Git first."
        missing_prereqs=true
    fi

    # Check DDEV
    if command -v ddev &> /dev/null; then
        print_success "DDEV: $(ddev version | head -n1)"
    else
        print_error "DDEV not found. Please install DDEV first: https://ddev.readthedocs.io/"
        missing_prereqs=true
    fi

    # Check Docker
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            print_success "Docker: Running"
        else
            print_error "Docker not running. Please start Docker."
            missing_prereqs=true
        fi
    else
        print_error "Docker not found. DDEV requires Docker."
        missing_prereqs=true
    fi

    if [ "$missing_prereqs" = true ]; then
        print_error "Missing prerequisites. Please install required tools and try again."
        exit 1
    fi
}

# Gather user input
gather_input() {
    print_header "Configuration"

    # Project name
    read -p "Project name (e.g., t3coredev-14-php8-4): " PROJECT_NAME
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="t3coredev-14-php8-4"
        print_info "Using default: $PROJECT_NAME"
    fi

    # Git user name
    read -p "Your name for Git commits: " GIT_NAME
    while [ -z "$GIT_NAME" ]; do
        print_error "Name is required"
        read -p "Your name for Git commits: " GIT_NAME
    done

    # Git email
    read -p "Your email for Git commits: " GIT_EMAIL
    while [ -z "$GIT_EMAIL" ]; do
        print_error "Email is required"
        read -p "Your email for Git commits: " GIT_EMAIL
    done

    # Gerrit username
    read -p "Your Gerrit username (review.typo3.org): " GERRIT_USER
    while [ -z "$GERRIT_USER" ]; do
        print_error "Gerrit username is required"
        read -p "Your Gerrit username: " GERRIT_USER
    done

    # PHP version
    read -p "PHP version (8.2, 8.3, 8.4) [default: 8.4]: " PHP_VERSION
    if [ -z "$PHP_VERSION" ]; then
        PHP_VERSION="8.4"
    fi

    # Timezone
    read -p "Timezone [default: Europe/Vienna]: " TIMEZONE
    if [ -z "$TIMEZONE" ]; then
        TIMEZONE="Europe/Vienna"
    fi

    # Admin password
    read -sp "TYPO3 admin password: " ADMIN_PASSWORD
    echo
    while [ -z "$ADMIN_PASSWORD" ]; do
        print_error "Admin password is required"
        read -sp "TYPO3 admin password: " ADMIN_PASSWORD
        echo
    done

    # Confirm
    echo -e "\n${YELLOW}Configuration Summary:${NC}"
    echo "  Project:        $PROJECT_NAME"
    echo "  Git Name:       $GIT_NAME"
    echo "  Git Email:      $GIT_EMAIL"
    echo "  Gerrit User:    $GERRIT_USER"
    echo "  PHP Version:    $PHP_VERSION"
    echo "  Timezone:       $TIMEZONE"
    echo

    read -p "Proceed with setup? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        print_info "Setup cancelled."
        exit 0
    fi
}

# Create project directory
create_project_dir() {
    print_header "Creating Project Directory"

    if [ -d "$PROJECT_NAME" ]; then
        print_error "Directory $PROJECT_NAME already exists!"
        read -p "Delete and recreate? (y/n): " DELETE_CONFIRM
        if [[ "$DELETE_CONFIRM" =~ ^[Yy]$ ]]; then
            rm -rf "$PROJECT_NAME"
            print_success "Deleted existing directory"
        else
            print_error "Cannot proceed with existing directory"
            exit 1
        fi
    fi

    mkdir -p "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    print_success "Created and entered directory: $PROJECT_NAME"
}

# Clone TYPO3 repository
clone_repository() {
    print_header "Cloning TYPO3 Repository"

    print_step "Cloning from GitHub..."
    if git clone git@github.com:typo3/typo3 . 2>&1 | grep -q "Permission denied\|Could not"; then
        print_error "Failed to clone via SSH. Trying HTTPS..."
        rm -rf .git
        if ! git clone https://github.com/typo3/typo3.git . ; then
            print_error "Failed to clone repository"
            exit 1
        fi
    fi

    print_success "Repository cloned successfully"
}

# Configure Git
configure_git() {
    print_header "Configuring Git"

    print_step "Setting user identity..."
    git config user.name "$GIT_NAME"
    git config user.email "$GIT_EMAIL"
    print_success "User identity configured"

    print_step "Enabling automatic rebase..."
    git config branch.autosetuprebase remote
    print_success "Automatic rebase enabled"

    print_step "Installing git hooks..."
    if [ -f "Build/git-hooks/commit-msg" ]; then
        cp Build/git-hooks/commit-msg .git/hooks/commit-msg
        chmod +x .git/hooks/commit-msg
        print_success "Commit-msg hook installed"
    else
        print_error "Commit-msg hook not found in Build/git-hooks/"
    fi

    print_step "Configuring Gerrit remote..."
    git config remote.origin.pushurl "ssh://${GERRIT_USER}@review.typo3.org:29418/Packages/TYPO3.CMS.git"
    git config remote.origin.push "+refs/heads/main:refs/for/main"
    print_success "Gerrit remote configured"

    # Test Gerrit connection
    print_step "Testing Gerrit SSH connection..."
    if timeout 5 ssh -p 29418 -o StrictHostKeyChecking=no -o BatchMode=yes "${GERRIT_USER}@review.typo3.org" gerrit version &>/dev/null; then
        print_success "Gerrit connection successful"
    else
        print_error "Cannot connect to Gerrit. Please verify your SSH keys are configured."
        print_info "Continue anyway? SSH key might need configuration."
        read -p "Continue? (y/n): " CONTINUE
        if [[ ! "$CONTINUE" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Configure DDEV
configure_ddev() {
    print_header "Configuring DDEV"

    print_step "Setting project type..."
    ddev config --project-type typo3 -y

    print_step "Configuring timezone..."
    ddev config --timezone "$TIMEZONE"

    print_step "Setting PHP version..."
    ddev config --php-version="$PHP_VERSION"

    print_step "Configuring webserver..."
    ddev config --webserver-type=apache-fpm

    print_step "Setting database version..."
    ddev config --database=mariadb:10.6

    print_step "Adding environment variables..."
    ddev config --web-environment-add="TYPO3_CONTEXT=Development/Ddev"
    ddev config --web-environment-add="COMPOSER_ROOT_VERSION=14.0.x-dev"

    print_success "DDEV configured successfully"
}

# Start DDEV
start_ddev() {
    print_header "Starting DDEV"

    print_step "Starting containers..."
    if ddev start; then
        print_success "DDEV started successfully"
        ddev describe
    else
        print_error "Failed to start DDEV"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    print_header "Installing Dependencies"

    print_step "Running Composer install via runTests.sh..."
    if ./Build/Scripts/runTests.sh -s composerInstall; then
        print_success "Dependencies installed"
    else
        print_error "Failed to install dependencies"
        print_info "Trying alternative method..."
        if ddev composer install; then
            print_success "Dependencies installed via ddev composer"
        else
            print_error "Failed to install dependencies"
            exit 1
        fi
    fi
}

# Setup TYPO3
setup_typo3() {
    print_header "Setting Up TYPO3"

    print_step "Creating installation trigger files..."
    ddev exec 'touch /var/www/html/FIRST_INSTALL'
    ddev exec 'touch /var/www/html/typo3conf/ENABLE_INSTALL_TOOL'
    ddev exec 'echo "KEEP_FILE" > /var/www/html/typo3conf/ENABLE_INSTALL_TOOL'
    print_success "Trigger files created"

    print_step "Running TYPO3 setup..."
    if ddev typo3 setup \
        --driver=mysqli \
        --host=db \
        --port=3306 \
        --dbname=db \
        --username=db \
        --password=db \
        --admin-username=backenduser \
        --admin-user-password="$ADMIN_PASSWORD" \
        --admin-email="$GIT_EMAIL" \
        --project-name="TYPO3 Core Dev v14 PHP ${PHP_VERSION}" \
        --no-interaction \
        --server-type=apache \
        --force; then
        print_success "TYPO3 setup completed"
    else
        print_error "TYPO3 setup failed"
        exit 1
    fi
}

# Activate extensions
activate_extensions() {
    print_header "Activating Extensions"

    print_step "Setting up extensions..."
    ddev typo3 extension:setup

    print_step "Activating indexed_search..."
    ddev typo3 extension:activate indexed_search

    print_step "Activating styleguide..."
    ddev typo3 extension:activate styleguide

    print_step "Activating scheduler..."
    ddev typo3 extension:activate scheduler

    print_success "Extensions activated"
}

# Setup backend groups
setup_backend_groups() {
    print_header "Setting Up Backend User Groups"

    print_step "Creating default backend groups..."
    if ddev typo3 setup:begroups:default --groups=Both; then
        print_success "Backend groups configured"
    else
        print_error "Failed to setup backend groups"
    fi
}

# Generate test data
generate_test_data() {
    print_header "Generating Test Data"

    read -p "Generate styleguide test data? (y/n): " GENERATE_DATA
    if [[ "$GENERATE_DATA" =~ ^[Yy]$ ]]; then
        print_step "Generating TCA examples..."
        ddev typo3 styleguide:generate --create -- tca

        print_step "Generating frontend system template..."
        ddev typo3 styleguide:generate --create -- frontend-systemplate

        print_success "Test data generated"
    else
        print_info "Skipping test data generation"
    fi
}

# Final steps
finalize() {
    print_header "Setup Complete!"

    print_success "TYPO3 Core development environment is ready!"
    echo
    echo -e "${GREEN}Project Details:${NC}"
    echo "  Name:           $PROJECT_NAME"
    echo "  URL:            https://${PROJECT_NAME}.ddev.site"
    echo "  Backend:        https://${PROJECT_NAME}.ddev.site/typo3"
    echo "  Admin User:     backenduser"
    echo "  Admin Password: [the password you entered]"
    echo
    echo -e "${GREEN}Next Steps:${NC}"
    echo "  1. Open backend:      ddev launch /typo3"
    echo "  2. Run tests:         ./Build/Scripts/runTests.sh -s unit"
    echo "  3. Create branch:     git checkout -b feature/your-feature"
    echo "  4. Make changes and commit with proper message"
    echo "  5. Push to Gerrit:    git push origin HEAD:refs/for/main"
    echo
    echo -e "${GREEN}Useful Commands:${NC}"
    echo "  ddev start            - Start project"
    echo "  ddev stop             - Stop project"
    echo "  ddev restart          - Restart project"
    echo "  ddev ssh              - SSH into container"
    echo "  ddev typo3 cache:flush - Clear TYPO3 caches"
    echo "  ddev logs -f          - Follow logs"
    echo

    read -p "Open TYPO3 backend now? (y/n): " OPEN_BACKEND
    if [[ "$OPEN_BACKEND" =~ ^[Yy]$ ]]; then
        ddev launch /typo3
    fi
}

# Main execution
main() {
    clear
    print_header "TYPO3 Core Development Setup"

    echo "This script will set up a complete TYPO3 Core development environment."
    echo "It will:"
    echo "  - Clone TYPO3 Core repository"
    echo "  - Configure Git for Gerrit submissions"
    echo "  - Set up DDEV with optimal settings"
    echo "  - Install TYPO3 with test data"
    echo "  - Activate development extensions"
    echo

    check_prerequisites
    gather_input
    create_project_dir
    clone_repository
    configure_git
    configure_ddev
    start_ddev
    install_dependencies
    setup_typo3
    activate_extensions
    setup_backend_groups
    generate_test_data
    finalize
}

# Run main function
main
