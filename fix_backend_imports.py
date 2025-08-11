#!/usr/bin/env python3
"""
Script to fix SecurityManager.get_current_user import issues in the backend
"""

import os
import re

def fix_file(file_path):
    """Fix SecurityManager.get_current_user references in a file"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if file needs fixing
    if 'SecurityManager.get_current_user' not in content:
        return False
    
    # Add import if not present
    if 'from app.core.security import SecurityManager, get_current_user' not in content:
        content = content.replace(
            'from app.core.security import SecurityManager',
            'from app.core.security import SecurityManager, get_current_user'
        )
    
    # Replace all SecurityManager.get_current_user with get_current_user
    content = content.replace('SecurityManager.get_current_user', 'get_current_user')
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    """Main function to fix all files"""
    backend_dir = 'fitsync-backend'
    endpoints_dir = os.path.join(backend_dir, 'app', 'api', 'v1', 'endpoints')
    
    files_to_fix = [
        os.path.join(endpoints_dir, 'auth.py'),
        os.path.join(endpoints_dir, 'users.py'),
        os.path.join(endpoints_dir, 'clothing.py'),
        os.path.join(endpoints_dir, 'ml_endpoints.py'),
        os.path.join(endpoints_dir, 'analyze.py'),
    ]
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_file(file_path):
                print(f"✅ Fixed: {file_path}")
                fixed_count += 1
            else:
                print(f"ℹ️  No changes needed: {file_path}")
        else:
            print(f"⚠️  File not found: {file_path}")
    
    print(f"\n🎉 Fixed {fixed_count} files!")

if __name__ == "__main__":
    main()
