try:
    from app.api.v1.activities import activities_bp
    print("✅ SUCCESS: activities.py imported successfully!")
    print(f"Blueprint name: {activities_bp.name}")
except Exception as e:
    print(f"❌ ERROR importing activities.py: {e}")
    print("Full error details:")
    import traceback
    traceback.print_exc()