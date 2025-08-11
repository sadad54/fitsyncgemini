#!/bin/bash

# FitSync Backend Setup Script
# This script helps you set up the FitSync backend for development

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check Python version
check_python_version() {
    if command_exists python3; then
        PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')
        REQUIRED_VERSION="3.8"
        
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 8) else 1)"; then
            print_success "Python $PYTHON_VERSION is installed and compatible"
        else
            print_error "Python $PYTHON_VERSION is installed but version $REQUIRED_VERSION+ is required"
            exit 1
        fi
    else
        print_error "Python 3.8+ is required but not installed"
        exit 1
    fi
}

# Function to check if virtual environment exists
check_venv() {
    if [ ! -d "venv" ]; then
        print_status "Creating virtual environment..."
        python3 -m venv venv
        print_success "Virtual environment created"
    else
        print_success "Virtual environment already exists"
    fi
}

# Function to activate virtual environment
activate_venv() {
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        source venv/Scripts/activate
    else
        source venv/bin/activate
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing Python dependencies..."
    pip install --upgrade pip
    pip install -r requirements.txt
    print_success "Dependencies installed successfully"
}

# Function to setup environment file
setup_env() {
    if [ ! -f ".env" ]; then
        print_status "Creating .env file from template..."
        cp env.example .env
        
        # Generate a secure secret key
        SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
        
        # Update .env file with generated secret key
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/your-super-secret-key-here-change-this-in-production/$SECRET_KEY/" .env
        else
            # Linux
            sed -i "s/your-super-secret-key-here-change-this-in-production/$SECRET_KEY/" .env
        fi
        
        print_success ".env file created with secure secret key"
        print_warning "Please review and update the .env file with your specific configuration"
    else
        print_success ".env file already exists"
    fi
}

# Function to check database connection
check_database() {
    print_status "Checking database connection..."
    
    # Check if PostgreSQL is running
    if command_exists pg_isready; then
        if pg_isready -h localhost -p 5432 >/dev/null 2>&1; then
            print_success "PostgreSQL is running"
        else
            print_warning "PostgreSQL is not running. Please start PostgreSQL before continuing."
            print_status "You can start PostgreSQL with: sudo service postgresql start"
        fi
    else
        print_warning "pg_isready not found. Please ensure PostgreSQL is installed and running."
    fi
}

# Function to check Redis
check_redis() {
    print_status "Checking Redis connection..."
    
    if command_exists redis-cli; then
        if redis-cli ping >/dev/null 2>&1; then
            print_success "Redis is running"
        else
            print_warning "Redis is not running. Please start Redis before continuing."
            print_status "You can start Redis with: redis-server"
        fi
    else
        print_warning "redis-cli not found. Please ensure Redis is installed and running."
    fi
}

# Function to create directories
create_directories() {
    print_status "Creating necessary directories..."
    mkdir -p uploads models chroma_db logs
    print_success "Directories created"
}

# Function to run database migrations
run_migrations() {
    print_status "Running database migrations..."
    if command_exists alembic; then
        alembic upgrade head
        print_success "Database migrations completed"
    else
        print_warning "Alembic not found. Please install it with: pip install alembic"
    fi
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    if command_exists pytest; then
        pytest -v
        print_success "Tests completed"
    else
        print_warning "pytest not found. Please install it with: pip install pytest"
    fi
}

# Function to start the application
start_application() {
    print_status "Starting FitSync backend..."
    print_success "Application will be available at: http://localhost:8000"
    print_success "API Documentation: http://localhost:8000/docs"
    print_success "Health Check: http://localhost:8000/health"
    
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
}

# Function to show help
show_help() {
    echo "FitSync Backend Setup Script"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  setup     - Complete setup (default)"
    echo "  install   - Install dependencies only"
    echo "  test      - Run tests only"
    echo "  start     - Start the application"
    echo "  help      - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup   # Complete setup"
    echo "  $0 install # Install dependencies"
    echo "  $0 test    # Run tests"
    echo "  $0 start   # Start application"
}

# Main function
main() {
    echo "🚀 FitSync Backend Setup Script"
    echo "================================"
    echo ""
    
    case "${1:-setup}" in
        "setup")
            print_status "Starting complete setup..."
            check_python_version
            check_venv
            activate_venv
            install_dependencies
            setup_env
            check_database
            check_redis
            create_directories
            run_migrations
            run_tests
            print_success "Setup completed successfully!"
            print_status "You can now start the application with: $0 start"
            ;;
        "install")
            check_python_version
            check_venv
            activate_venv
            install_dependencies
            print_success "Dependencies installed successfully!"
            ;;
        "test")
            activate_venv
            run_tests
            ;;
        "start")
            activate_venv
            start_application
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
