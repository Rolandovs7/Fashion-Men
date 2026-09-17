#!/bin/bash

set -e

echo "🧹 Limpiando pantalla inicial de Angular..."

cat > src/app/app.html <<'EOF'
<router-outlet></router-outlet>
EOF

cat > src/app/app.css <<'EOF'
* {
  box-sizing: border-box;
}

html,
body {
  margin: 0;
  padding: 0;
  min-height: 100%;
  font-family: Arial, Helvetica, sans-serif;
}

body {
  background: #f4f4f5;
}
EOF

echo "✅ Pantalla inicial de Angular eliminada."
echo "🚀 MenStyle ahora utiliza únicamente sus rutas."
