#!/usr/bin/env python3
"""
Script para integrar el sistema de bienvenida en index.html
"""

# Leer el archivo index.html
with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()

# Leer welcome-temp.html
with open('welcome-temp.html', 'r', encoding='utf-8') as f:
    welcome_content = f.read()

# ============================================================================
# 1. EXTRAER CSS DE WELCOME-TEMP.HTML (líneas 19-377)
# ============================================================================
css_start = welcome_content.find('        /* Pantalla de bienvenida con partículas */')
css_end = welcome_content.find('    </style>\n</head>')
welcome_css = welcome_content[css_start:css_end]

# Insertar CSS antes de </style> en index.html
style_end = content.find('    </style>\n</head>')
content = content[:style_end] + '\n' + welcome_css + '\n' + content[style_end:]

print("✅ CSS integrado")

# ============================================================================
# 2. EXTRAER HTML DEL OVERLAY (líneas 380-419)
# ============================================================================
html_start = welcome_content.find('    <!-- Canvas para partículas -->')
html_end = welcome_content.find('    </div>\n\n    <script>')
welcome_html = welcome_content[html_start:html_end + len('    </div>')]

# Insertar HTML después de <body>
body_start = content.find('<body>\n')
content = content[:body_start + 7] + welcome_html + '\n\n' + content[body_start + 7:]

print("✅ HTML del overlay integrado")

# ============================================================================
# 3. AÑADIR SALUDO PERSONALIZADO EN HOME-SCREEN
# ============================================================================
user_greeting_html = '''
        <!-- Saludo personalizado del usuario (se muestra después de identificarse) -->
        <div class="user-greeting" id="user-greeting" style="display: none;">
            <div class="user-greeting-text">¡Hola, <span id="greeting-name"></span>!</div>
            <div class="user-greeting-subtitle">Tu código de identificación</div>
            <div class="user-code-badge" id="greeting-code"></div>
            <button class="logout-btn" onclick="logout()" style="position: static; margin-top: 15px;">
                🚪 Cerrar sesión
            </button>
        </div>
'''

# Buscar donde insertar el saludo (después del subtitle del home-screen)
home_subtitle_pos = content.find('<p>Bienvenido - Selecciona una opción</p>')
insert_pos = content.find('</div>', home_subtitle_pos)  # Encuentra el </div> después del <p>
content = content[:insert_pos] + user_greeting_html + '\n' + content[insert_pos:]

print("✅ Saludo personalizado añadido")

# ============================================================================
# 4. EXTRAER Y MODIFICAR JAVASCRIPT
# ============================================================================
js_start = welcome_content.find('        // Sistema de partículas animadas')
js_end = welcome_content.find('    </script>\n</body>')
welcome_js = welcome_content[js_start:js_end]

# Modificar la función showUserGreeting para usar el div en index.html
welcome_js = welcome_js.replace(
    '''        // Mostrar saludo personalizado
        function showUserGreeting() {
            const userName = localStorage.getItem('userName');
            const userCode = localStorage.getItem('attendeeCode');

            if (userName) {
                alert(`¡Perfecto! Sistema implementado.\\n\\nUsuario: ${userName}\\nCódigo: ${userCode}\\n\\nEste saludo se mostrará en el home screen.`);
            }
        }''',
    '''        // Mostrar saludo personalizado
        function showUserGreeting() {
            const userName = localStorage.getItem('userName');
            const userCode = localStorage.getItem('attendeeCode');

            if (userName) {
                const greetingDiv = document.getElementById('user-greeting');
                const greetingName = document.getElementById('greeting-name');
                const greetingCode = document.getElementById('greeting-code');

                if (greetingDiv && greetingName && greetingCode) {
                    greetingName.textContent = userName;
                    greetingCode.textContent = userCode;
                    greetingDiv.style.display = 'block';
                }
            }
        }'''
)

# Reemplazar el window.onload del welcome por checkExistingSession
welcome_js = welcome_js.replace(
    '''        // Verificar si ya hay sesión al cargar
        window.onload = function() {
            const userName = localStorage.getItem('userName');
            const userEmail = localStorage.getItem('userEmail');

            if (userName && userEmail) {
                // Mostrar botón de logout
                document.getElementById('logout-btn').style.display = 'block';

                // Cerrar overlay automáticamente
                setTimeout(() => {
                    closeWelcomeOverlay();
                }, 500);
            }
        };''',
    '''        // Verificar si ya hay sesión existente
        function checkExistingSession() {
            const userName = localStorage.getItem('userName');
            const userEmail = localStorage.getItem('userEmail');

            if (userName && userEmail) {
                // Mostrar botón de logout en el overlay
                const logoutBtn = document.getElementById('logout-btn');
                if (logoutBtn) {
                    logoutBtn.style.display = 'block';
                }

                // Cerrar overlay automáticamente
                setTimeout(() => {
                    closeWelcomeOverlay();
                }, 500);
            }
        }'''
)

# Insertar JavaScript antes del </script> final
script_end_pos = content.rfind('    </script>\n</body>')
content = content[:script_end_pos] + '\n' + welcome_js + '\n' + content[script_end_pos:]

print("✅ JavaScript integrado")

# ============================================================================
# 5. MODIFICAR window.onload PARA AÑADIR checkExistingSession()
# ============================================================================
window_onload_pos = content.find('window.onload = async function() {')
after_function_open = content.find('{', window_onload_pos) + 1
# Encontrar la primera línea después del {
next_newline = content.find('\n', after_function_open)
content = content[:next_newline + 1] + '            checkExistingSession();\n' + content[next_newline + 1:]

print("✅ window.onload modificado")

# ============================================================================
# 6. GUARDAR ARCHIVO
# ============================================================================
with open('index.html', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n🎉 ¡Integración completada exitosamente!")
print("📄 index.html ha sido actualizado")
print("🔍 Abre index.html en tu navegador para probar el sistema")
