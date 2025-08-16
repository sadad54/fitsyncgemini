#!/usr/bin/env python3
"""
Fix enum values in the database by converting string values to proper enum values
"""
import sqlite3
import os

def fix_enum_values():
    """Fix enum values in the clothing_items table"""
    
    db_path = "fitsync.db"
    if not os.path.exists(db_path):
        print(f"❌ Database file not found: {db_path}")
        return
    
    print(f"✅ Database file found: {db_path}")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Define the mapping from string values to enum values
        category_mapping = {
            'tops': 'TOPS',
            'bottoms': 'BOTTOMS', 
            'dresses': 'DRESSES',
            'outerwear': 'OUTERWEAR',
            'shoes': 'SHOES',
            'accessories': 'ACCESSORIES',
            'underwear': 'UNDERWEAR',
            'swimwear': 'SWIMWEAR',
            'activewear': 'ACTIVEWEAR',
            'formalwear': 'FORMALWEAR'
        }
        
        subcategory_mapping = {
            't_shirts': 'T_SHIRTS',
            'shirts': 'SHIRTS',
            'blouses': 'BLOUSES',
            'sweaters': 'SWEATERS',
            'hoodies': 'HOODIES',
            'tank_tops': 'TANK_TOPS',
            'jeans': 'JEANS',
            'pants': 'PANTS',
            'shorts': 'SHORTS',
            'skirts': 'SKIRTS',
            'leggings': 'LEGGINGS',
            'casual_dresses': 'CASUAL_DRESSES',
            'formal_dresses': 'FORMAL_DRESSES',
            'maxi_dresses': 'MAXI_DRESSES',
            'mini_dresses': 'MINI_DRESSES',
            'jackets': 'JACKETS',
            'coats': 'COATS',
            'blazers': 'BLAZERS',
            'cardigans': 'CARDIGANS',
            'sneakers': 'SNEAKERS',
            'boots': 'BOOTS',
            'heels': 'HEELS',
            'flats': 'FLATS',
            'sandals': 'SANDALS',
            'bags': 'BAGS',
            'jewelry': 'JEWELRY',
            'scarves': 'SCARVES',
            'belts': 'BELTS',
            'hats': 'HATS'
        }
        
        # Check current values
        print("📊 Current category values in database:")
        cursor.execute("SELECT DISTINCT category FROM clothing_items WHERE category IS NOT NULL")
        current_categories = cursor.fetchall()
        for cat in current_categories:
            print(f"  - {cat[0]}")
        
        print("\n📊 Current subcategory values in database:")
        cursor.execute("SELECT DISTINCT subcategory FROM clothing_items WHERE subcategory IS NOT NULL")
        current_subcategories = cursor.fetchall()
        for subcat in current_subcategories:
            print(f"  - {subcat[0]}")
        
        # Update category values
        print("\n🔄 Updating category values...")
        for old_value, new_value in category_mapping.items():
            cursor.execute(
                "UPDATE clothing_items SET category = ? WHERE category = ?",
                (new_value, old_value)
            )
            affected = cursor.rowcount
            if affected > 0:
                print(f"  ✅ Updated {affected} items: '{old_value}' -> '{new_value}'")
        
        # Update subcategory values
        print("\n🔄 Updating subcategory values...")
        for old_value, new_value in subcategory_mapping.items():
            cursor.execute(
                "UPDATE clothing_items SET subcategory = ? WHERE subcategory = ?",
                (new_value, old_value)
            )
            affected = cursor.rowcount
            if affected > 0:
                print(f"  ✅ Updated {affected} items: '{old_value}' -> '{new_value}'")
        
        # Commit changes
        conn.commit()
        
        # Verify the changes
        print("\n📊 Updated category values:")
        cursor.execute("SELECT DISTINCT category FROM clothing_items WHERE category IS NOT NULL")
        updated_categories = cursor.fetchall()
        for cat in updated_categories:
            print(f"  - {cat[0]}")
        
        print("\n📊 Updated subcategory values:")
        cursor.execute("SELECT DISTINCT subcategory FROM clothing_items WHERE subcategory IS NOT NULL")
        updated_subcategories = cursor.fetchall()
        for subcat in updated_subcategories:
            print(f"  - {subcat[0]}")
        
        print("\n✅ Enum values fixed successfully!")
        
        conn.close()
        
    except Exception as e:
        print(f"❌ Error fixing enum values: {e}")
        if 'conn' in locals():
            conn.rollback()
            conn.close()

if __name__ == "__main__":
    fix_enum_values()
