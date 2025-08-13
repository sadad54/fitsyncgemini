#!/usr/bin/env python3
"""
Script to fix the database schema by adding missing columns.
Run this script to update the existing database.
"""

import asyncio
import sqlite3
from pathlib import Path

async def fix_database():
    """Add missing columns to the users table."""
    db_path = Path("fitsync.db")
    
    if not db_path.exists():
        print("Database file not found. Creating new database...")
        return
    
    print("Fixing database schema...")
    
    # Connect to the database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check if first_name column exists
        cursor.execute("PRAGMA table_info(users)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'first_name' not in columns:
            print("Adding first_name column...")
            cursor.execute("ALTER TABLE users ADD COLUMN first_name VARCHAR(100)")
        
        if 'last_name' not in columns:
            print("Adding last_name column...")
            cursor.execute("ALTER TABLE users ADD COLUMN last_name VARCHAR(100)")
        
        # Commit changes
        conn.commit()
        print("Database schema updated successfully!")
        
    except Exception as e:
        print(f"Error updating database: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    asyncio.run(fix_database())
