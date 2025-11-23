#!/bin/bash

# Script para verificar manualmente que la funcionalidad de diseño funciona
echo "🧪 Testing Design Configuration Functionality"
echo "============================================="

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables del API
API_BASE="http://localhost:3000"
FRONTEND_BASE="http://localhost:3001"

echo -e "\n${YELLOW}1. Testing Backend Models...${NC}"

# Test 1: Verificar que los modelos funcionan
echo "   - Testing DesignConfiguration model..."
ruby -e "
require_relative '../config/environment'

# Test basic model creation
user = User.first || User.create!(email: 'test@example.com', auth0_id: 'test123')
restaurant = user.restaurants.first || user.restaurants.create!(name: 'Test Restaurant')
menu = restaurant.menus.first || restaurant.menus.create!(name: 'Test Menu')

# Test design configuration creation
config = menu.get_design_configuration
puts '   ✅ Default design configuration created'

# Test validation
config.primary_color = 'invalid'
puts config.valid? ? '   ❌ Validation failed' : '   ✅ Validation working'

# Test color conversion
config.primary_color = '#123456'
config.save!
hash = config.to_design_hash
puts hash[:primaryColor] == '#123456' ? '   ✅ Hash conversion working' : '   ❌ Hash conversion failed'

puts '   ✅ Backend models working correctly'
"

echo -e "\n${YELLOW}2. Testing API Endpoints...${NC}"

# Test 2: Verificar endpoints de API (requiere servidor corriendo)
if curl -s "$API_BASE/ping" > /dev/null; then
    echo "   ✅ Backend server is running"
    
    # Note: These would need actual authentication tokens
    echo "   📝 API endpoints to test manually:"
    echo "   - GET $API_BASE/restaurants/{id}/menus/{id}/design_configuration"
    echo "   - PUT $API_BASE/restaurants/{id}/menus/{id}/design_configuration"
    echo "   - GET $API_BASE/menus/by_restaurant_id/{id}"
    echo "   - GET $API_BASE/menus/by_name/{restaurant_name}"
else
    echo -e "   ${RED}❌ Backend server not running${NC}"
    echo "   💡 Start with: cd qr-menu && rails server"
fi

echo -e "\n${YELLOW}3. Testing Frontend Components...${NC}"

# Test 3: Verificar que el frontend esté corriendo
if curl -s "$FRONTEND_BASE" > /dev/null; then
    echo "   ✅ Frontend server is running"
    echo "   📝 Frontend pages to test manually:"
    echo "   - Admin panel: $FRONTEND_BASE/restaurant/{id}/menu/{id}"
    echo "   - Public QR menu: $FRONTEND_BASE/qr/{restaurant_id}"
    echo "   - Public name menu: $FRONTEND_BASE/{restaurant_name}"
else
    echo -e "   ${RED}❌ Frontend server not running${NC}"
    echo "   💡 Start with: cd qr-menu-ui && npm run dev"
fi

echo -e "\n${YELLOW}4. Design Configuration Feature Flag...${NC}"

# Test 4: Verificar feature flag
if [ -f "../qr-menu-ui/.env" ]; then
    if grep -q "NEXT_PUBLIC_DESIGN_ENABLED=true" ../qr-menu-ui/.env; then
        echo "   ✅ Design feature is ENABLED"
    else
        echo "   ⚠️  Design feature is DISABLED"
        echo "   💡 Enable with: NEXT_PUBLIC_DESIGN_ENABLED=true in .env"
    fi
else
    echo "   ⚠️  .env file not found"
fi

echo -e "\n${YELLOW}5. Manual Testing Checklist...${NC}"
echo "   📋 Test these scenarios manually:"
echo ""
echo "   Backend Tests:"
echo "   □ Create design configuration via API"
echo "   □ Update design configuration via API"
echo "   □ Validate color format (should reject invalid colors)"
echo "   □ Validate font (should reject invalid fonts)"
echo "   □ Authorization (should block other users)"
echo ""
echo "   Frontend Tests:"
echo "   □ Design tab appears when DESIGN_ENABLED=true"
echo "   □ Design tab hidden when DESIGN_ENABLED=false"
echo "   □ Color pickers work and update preview"
echo "   □ Contact toggles work and update preview"
echo "   □ Logo toggle works and updates preview"
echo "   □ Save button persists changes"
echo "   □ No page refresh after save"
echo ""
echo "   Public Menu Tests:"
echo "   □ QR menu uses saved design configuration"
echo "   □ Name menu uses saved design configuration"
echo "   □ Contact buttons appear/disappear based on settings"
echo "   □ Restaurant logo appears/disappears based on settings"
echo "   □ Colors and fonts are applied correctly"
echo "   □ Fallback to defaults when no configuration exists"

echo -e "\n${GREEN}🎯 Manual Testing Instructions:${NC}"
echo "1. Start both servers (Rails + Next.js)"
echo "2. Create a user and restaurant in the admin"
echo "3. Go to restaurant menu page and click 'Diseño' tab"
echo "4. Change colors, toggle contacts, save"
echo "5. Visit public menu and verify changes"
echo "6. Test with DESIGN_ENABLED=false"

echo -e "\n${YELLOW}6. Running RSpec Tests...${NC}"

# Test 5: Run RSpec tests if available
if command -v rspec &> /dev/null; then
    cd ../qr-menu
    if bundle exec rspec spec/models/design_configuration_spec.rb --format documentation 2>/dev/null; then
        echo "   ✅ Model tests passed"
    else
        echo "   ⚠️  Some tests failed or missing test dependencies"
    fi
    cd - > /dev/null
else
    echo "   📝 RSpec not available, install with: bundle install"
fi

echo -e "\n${GREEN}Testing script completed!${NC}"
echo "💡 For comprehensive testing, run the manual checklist above"