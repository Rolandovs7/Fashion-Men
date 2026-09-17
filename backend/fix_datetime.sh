#!/bin/bash

echo "=========================================="
echo "  CORRIGIENDO datetime.utcnow()"
echo "=========================================="

cd ~/Escritorio/MenStyle/backend

# 1. CORREGIR SERVICIOS
echo "📦 Corrigiendo servicios..."

# notification_service.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' app/services/notification_service.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' app/services/notification_service.py

# return_service.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' app/services/return_service.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' app/services/return_service.py

# payment_service.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' app/services/payment_service.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' app/services/payment_service.py

echo "✅ Servicios corregidos"

# 2. CORREGIR TESTS
echo "📦 Corrigiendo tests..."

# test_reservations.py
sed -i 's/from datetime import datetime, timedelta/from datetime import datetime, timedelta, timezone/g' tests/test_reservations.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' tests/test_reservations.py

# test_orders.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' tests/test_orders.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' tests/test_orders.py

# test_payments.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' tests/test_payments.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' tests/test_payments.py

# test_returns.py
sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' tests/test_returns.py
sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' tests/test_returns.py

echo "✅ Tests corregidos"

# 3. CORREGIR MODELOS (si hay)
echo "📦 Corrigiendo modelos..."

# Buscar y corregir en modelos
find app/models -name "*.py" -exec sed -i 's/from datetime import datetime/from datetime import datetime, timezone/g' {} \;
find app/models -name "*.py" -exec sed -i 's/datetime.utcnow()/datetime.now(timezone.utc)/g' {} \;

echo "✅ Modelos corregidos"

echo "=========================================="
echo "✅ ¡TODOS LOS ARCHIVOS CORREGIDOS!"
echo "=========================================="

# 4. Ejecutar tests
echo ""
echo "🧪 Ejecutando tests..."
echo ""

source venv/bin/activate
python -m pytest -v

echo ""
echo "=========================================="
echo "  FIN DEL PROCESO"
echo "=========================================="
