import sqlite3
import os

def fix_style_preferences_table():
    """Add missing columns to style_preferences table"""
    db_path = 'fitsync.db'
    
    if not os.path.exists(db_path):
        print(f"❌ Database file {db_path} not found!")
        return
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Check current table structure
        cursor.execute("PRAGMA table_info(style_preferences)")
        columns = [col[1] for col in cursor.fetchall()]
        print(f"Current columns: {columns}")
        
        # Add missing columns if they don't exist
        missing_columns = []
        
        if 'style_archetype' not in columns:
            missing_columns.append('style_archetype')
            cursor.execute("ALTER TABLE style_preferences ADD COLUMN style_archetype VARCHAR(100)")
            print("✅ Added style_archetype column")
        
        if 'quiz_results' not in columns:
            missing_columns.append('quiz_results')
            cursor.execute("ALTER TABLE style_preferences ADD COLUMN quiz_results JSON")
            print("✅ Added quiz_results column")
        
        if 'fit_preferences' not in columns:
            missing_columns.append('fit_preferences')
            cursor.execute("ALTER TABLE style_preferences ADD COLUMN fit_preferences JSON")
            print("✅ Added fit_preferences column")
        
        if not missing_columns:
            print("✅ All required columns already exist!")
        else:
            print(f"✅ Added {len(missing_columns)} missing columns: {missing_columns}")
        
        # Verify the changes
        cursor.execute("PRAGMA table_info(style_preferences)")
        updated_columns = [col[1] for col in cursor.fetchall()]
        print(f"Updated columns: {updated_columns}")
        
        conn.commit()
        
    except Exception as e:
        print(f"❌ Error fixing style_preferences table: {e}")
        conn.rollback()
    finally:
        conn.close()

if __name__ == "__main__":
    print("🔧 Fixing style_preferences table...")
    fix_style_preferences_table()
    print("✅ Done!")
