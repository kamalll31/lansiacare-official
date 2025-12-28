from app import create_app

app = create_app()

print("🎯 === ALL REGISTERED ROUTES ===")
print(f"{'ENDPOINT':<40} {'METHODS':<20} {'URL RULE'}")
print("=" * 80)

routes_found = False
for rule in app.url_map.iter_rules():
    if 'api/v1' in rule.rule:
        print(f"{rule.endpoint:<40} {str(rule.methods):<20} {rule.rule}")
        routes_found = True

if not routes_found:
    print("❌ No API routes found!")
    
print("\n🔍 === CHECKING SPECIFICALLY FOR ACTIVITIES ===")
activities_found = False
for rule in app.url_map.iter_rules():
    if 'activities' in rule.endpoint:
        print(f"✅ FOUND: {rule.endpoint} -> {rule.rule}")
        activities_found = True

if not activities_found:
    print("❌ NO ACTIVITIES ROUTES FOUND!")
    
print("\n📋 === ALL BLUEPRINTS ===")
for name, blueprint in app.blueprints.items():
    print(f"Blueprint: {name}")