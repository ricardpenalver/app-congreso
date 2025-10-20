#!/bin/bash

# Script para integrar el sistema de bienvenida en index.html
# Uso: bash integrate-welcome.sh

set -e  # Salir si hay error

echo "🚀 Iniciando integración del sistema de bienvenida..."

# Verificar que existen los archivos necesarios
if [ ! -f "index.html" ]; then
    echo "❌ Error: No se encuentra index.html"
    exit 1
fi

if [ ! -f "welcome-temp.html" ]; then
    echo "❌ Error: No se encuentra welcome-temp.html"
    exit 1
fi

# Crear backup
echo "📦 Creando backup..."
cp index.html index.html.backup-$(date +%Y%m%d-%H%M%S)
echo "✅ Backup creado"

# Extraer CSS del welcome-temp.html
echo "🎨 Extrayendo estilos CSS..."
cat > welcome-styles.tmp << 'EOF'

        /* ==================== SISTEMA DE BIENVENIDA - ESTILOS ==================== */

        /* Pantalla de bienvenida con partículas */
        #welcome-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 10000;
            animation: gradientShift 10s ease infinite;
            background-size: 200% 200%;
        }

        @keyframes gradientShift {
            0%, 100% { background-position: 0% 50%; }
            50% { background-position: 100% 50%; }
        }

        /* Canvas para partículas */
        #particles-canvas {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            z-index: 9999;
            pointer-events: none;
        }

        /* Contenedor del formulario */
        .welcome-container {
            position: relative;
            z-index: 2;
            background: rgba(255, 255, 255, 0.15);
            backdrop-filter: blur(20px);
            border-radius: 30px;
            padding: 50px 40px;
            max-width: 500px;
            width: 90%;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            border: 1px solid rgba(255, 255, 255, 0.3);
            animation: slideUp 0.8s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes slideUp {
            from {
                opacity: 0;
                transform: translateY(50px) scale(0.95);
            }
            to {
                opacity: 1;
                transform: translateY(0) scale(1);
            }
        }

        .welcome-icon {
            text-align: center;
            margin-bottom: 30px;
            animation: float 3s ease-in-out infinite;
        }

        .welcome-icon span {
            font-size: 80px;
            display: inline-block;
            filter: drop-shadow(0 10px 20px rgba(0, 0, 0, 0.3));
        }

        @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-20px); }
        }

        .welcome-title {
            text-align: center;
            color: white;
            font-size: 32px;
            font-weight: 800;
            margin-bottom: 15px;
            text-shadow: 0 4px 12px rgba(0, 0, 0, 0.3);
            letter-spacing: -0.5px;
        }

        .welcome-subtitle {
            text-align: center;
            color: rgba(255, 255, 255, 0.9);
            font-size: 16px;
            margin-bottom: 40px;
            text-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
        }

        .welcome-form {
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        .input-group {
            position: relative;
        }

        .input-group input {
            width: 100%;
            padding: 18px 20px;
            border: 2px solid rgba(255, 255, 255, 0.3);
            border-radius: 15px;
            background: rgba(255, 255, 255, 0.2);
            color: white;
            font-size: 16px;
            transition: all 0.3s;
            backdrop-filter: blur(10px);
        }

        .input-group input::placeholder {
            color: rgba(255, 255, 255, 0.7);
        }

        .input-group input:focus {
            outline: none;
            border-color: white;
            background: rgba(255, 255, 255, 0.3);
            box-shadow: 0 8px 25px rgba(0, 0, 0, 0.2);
            transform: translateY(-2px);
        }

        .input-icon {
            position: absolute;
            left: 20px;
            top: 50%;
            transform: translateY(-50%);
            font-size: 20px;
            pointer-events: none;
        }

        .input-group.with-icon input {
            padding-left: 55px;
        }

        .welcome-btn {
            padding: 18px 30px;
            border: none;
            border-radius: 15px;
            background: linear-gradient(135deg, #ffffff 0%, #f0f0f0 100%);
            color: #667eea;
            font-size: 18px;
            font-weight: 700;
            cursor: pointer;
            transition: all 0.3s;
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
            margin-top: 10px;
            position: relative;
            overflow: hidden;
        }

        .welcome-btn:hover {
            transform: translateY(-3px);
            box-shadow: 0 15px 40px rgba(0, 0, 0, 0.3);
        }

        .welcome-btn:active {
            transform: translateY(-1px);
        }

        .welcome-btn::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(102, 126, 234, 0.2);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
        }

        .welcome-btn:hover::before {
            width: 300px;
            height: 300px;
        }

        .welcome-btn span {
            position: relative;
            z-index: 1;
        }

        .recovery-link {
            text-align: center;
            margin-top: 20px;
        }

        .recovery-link a {
            color: white;
            text-decoration: none;
            font-size: 14px;
            opacity: 0.8;
            transition: opacity 0.3s;
            text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
        }

        .recovery-link a:hover {
            opacity: 1;
            text-decoration: underline;
        }

        .welcome-overlay.fade-out {
            animation: fadeOut 1s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }

        @keyframes fadeOut {
            0% {
                opacity: 1;
                transform: scale(1);
            }
            100% {
                opacity: 0;
                transform: scale(1.1);
                pointer-events: none;
            }
        }

        .user-greeting {
            text-align: center;
            padding: 20px;
            margin-bottom: 20px;
            background: linear-gradient(135deg, rgba(102, 126, 234, 0.1) 0%, rgba(118, 75, 162, 0.1) 100%);
            border-radius: 20px;
            border: 2px solid rgba(102, 126, 234, 0.2);
            animation: slideDown 0.6s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes slideDown {
            from {
                opacity: 0;
                transform: translateY(-20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }

        .user-greeting-text {
            font-size: 24px;
            font-weight: 700;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            background-clip: text;
            margin-bottom: 5px;
        }

        .user-greeting-subtitle {
            font-size: 14px;
            color: #666;
        }

        .user-code-badge {
            display: inline-block;
            margin-top: 10px;
            padding: 8px 15px;
            background: white;
            border-radius: 20px;
            font-size: 12px;
            color: #667eea;
            font-weight: 600;
            box-shadow: 0 4px 15px rgba(102, 126, 234, 0.2);
        }

        .logout-btn {
            position: absolute;
            top: 20px;
            right: 20px;
            background: rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.3);
            padding: 10px 20px;
            border-radius: 20px;
            color: white;
            font-size: 12px;
            cursor: pointer;
            transition: all 0.3s;
            z-index: 10001;
        }

        .logout-btn:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-2px);
        }

        .recovery-mode .welcome-title {
            font-size: 28px;
        }

        .recovery-mode .welcome-subtitle {
            margin-bottom: 30px;
        }

        .back-to-welcome {
            text-align: center;
            margin-top: 20px;
        }

        .back-to-welcome a {
            color: white;
            text-decoration: none;
            font-size: 14px;
            opacity: 0.8;
            transition: opacity 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }

        .back-to-welcome a:hover {
            opacity: 1;
        }

        .error-message {
            background: rgba(220, 53, 69, 0.2);
            border: 2px solid rgba(220, 53, 69, 0.5);
            color: white;
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 20px;
            text-align: center;
            font-size: 14px;
            backdrop-filter: blur(10px);
            animation: shake 0.5s;
        }

        .welcome-btn.loading {
            pointer-events: none;
            opacity: 0.7;
        }

        .welcome-btn.loading span::after {
            content: '...';
            animation: dots 1.5s steps(3, end) infinite;
        }

        @keyframes dots {
            0%, 20% { content: '.'; }
            40% { content: '..'; }
            60%, 100% { content: '...'; }
        }

        /* ==================== FIN SISTEMA DE BIENVENIDA ==================== */
EOF

echo "✅ Estilos CSS extraídos"

# Insertar CSS antes del cierre de </style>
echo "📝 Insertando estilos en index.html..."
perl -i -pe 'BEGIN{undef $/;} s{(</style>)}{`cat welcome-styles.tmp`\n$1}smg' index.html
echo "✅ Estilos CSS insertados"

# Crear HTML del overlay
echo "🎨 Creando HTML del overlay..."
cat > welcome-html.tmp << 'EOF'
    <!-- Canvas para partículas animadas -->
    <canvas id="particles-canvas" style="display: none;"></canvas>

    <!-- Overlay de bienvenida -->
    <div id="welcome-overlay" style="display: none;">
        <button class="logout-btn" id="logout-btn" style="display: none;" onclick="logout()">
            🚪 Cerrar sesión
        </button>

        <div class="welcome-container" id="welcome-container">
            <div class="welcome-icon">
                <span>🎉</span>
            </div>
            <h1 class="welcome-title">¡Bienvenido!</h1>
            <p class="welcome-subtitle">Para comenzar, necesitamos conocerte</p>

            <div id="error-container"></div>

            <form class="welcome-form" id="welcome-form" onsubmit="submitWelcome(event)">
                <div class="input-group with-icon">
                    <span class="input-icon">👤</span>
                    <input type="text" id="user-name" placeholder="Tu nombre" required autocomplete="given-name">
                </div>

                <div class="input-group with-icon">
                    <span class="input-icon">📧</span>
                    <input type="email" id="user-email" placeholder="tu@email.com" required autocomplete="email">
                </div>

                <button type="submit" class="welcome-btn">
                    <span>Comenzar experiencia</span>
                </button>
            </form>

            <div class="recovery-link">
                <a href="#" onclick="showRecoveryMode(event)">¿Ya tienes una cuenta? Recuperar sesión</a>
            </div>
        </div>
    </div>

EOF

echo "✅ HTML del overlay creado"

# Insertar HTML después de <body>
echo "📝 Insertando HTML en index.html..."
perl -i -pe 's{(<body>)}{$1\n`cat welcome-html.tmp`}' index.html
echo "✅ HTML del overlay insertado"

# Crear saludo personalizado para home-screen
echo "🎨 Creando HTML del saludo personalizado..."
cat > user-greeting.tmp << 'EOF'

            <!-- Saludo personalizado del usuario -->
            <div id="user-greeting-container" style="display: none;">
                <div class="user-greeting">
                    <div class="user-greeting-text" id="user-greeting-text"></div>
                    <div class="user-greeting-subtitle">Bienvenido al congreso</div>
                    <div class="user-code-badge" id="user-code-badge"></div>
                </div>
            </div>
EOF

echo "✅ HTML del saludo creado"

# Insertar saludo después del header en home-screen
echo "📝 Insertando saludo en home-screen..."
perl -i -pe 's{(<div id="home-screen".*?<div class="header">.*?</div>)}{$1`cat user-greeting.tmp`}s' index.html
echo "✅ Saludo insertado"

# Crear JavaScript
echo "⚙️ Creando funciones JavaScript..."
cat > welcome-js.tmp << 'EOF'

        // ==================== SISTEMA DE BIENVENIDA - JAVASCRIPT ====================

        // Sistema de partículas animadas
        (function initParticles() {
            const canvas = document.getElementById('particles-canvas');
            if (!canvas) return;

            const ctx = canvas.getContext('2d');
            canvas.width = window.innerWidth;
            canvas.height = window.innerHeight;

            const particles = [];
            const particleCount = 50;

            class Particle {
                constructor() {
                    this.x = Math.random() * canvas.width;
                    this.y = Math.random() * canvas.height;
                    this.size = Math.random() * 3 + 1;
                    this.speedX = Math.random() * 2 - 1;
                    this.speedY = Math.random() * 2 - 1;
                    this.opacity = Math.random() * 0.5 + 0.2;
                }

                update() {
                    this.x += this.speedX;
                    this.y += this.speedY;
                    if (this.x > canvas.width) this.x = 0;
                    if (this.x < 0) this.x = canvas.width;
                    if (this.y > canvas.height) this.y = 0;
                    if (this.y < 0) this.y = canvas.height;
                }

                draw() {
                    ctx.fillStyle = `rgba(255, 255, 255, ${this.opacity})`;
                    ctx.beginPath();
                    ctx.arc(this.x, this.y, this.size, 0, Math.PI * 2);
                    ctx.fill();
                }
            }

            for (let i = 0; i < particleCount; i++) {
                particles.push(new Particle());
            }

            function animate() {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
                particles.forEach(particle => {
                    particle.update();
                    particle.draw();
                });

                for (let i = 0; i < particles.length; i++) {
                    for (let j = i + 1; j < particles.length; j++) {
                        const dx = particles[i].x - particles[j].x;
                        const dy = particles[i].y - particles[j].y;
                        const distance = Math.sqrt(dx * dx + dy * dy);

                        if (distance < 100) {
                            ctx.strokeStyle = `rgba(255, 255, 255, ${0.2 * (1 - distance / 100)})`;
                            ctx.lineWidth = 1;
                            ctx.beginPath();
                            ctx.moveTo(particles[i].x, particles[i].y);
                            ctx.lineTo(particles[j].x, particles[j].y);
                            ctx.stroke();
                        }
                    }
                }

                requestAnimationFrame(animate);
            }

            animate();

            window.addEventListener('resize', () => {
                canvas.width = window.innerWidth;
                canvas.height = window.innerHeight;
            });
        })();

        // Función para generar hash SHA-256
        async function hashEmail(email) {
            const msgBuffer = new TextEncoder().encode(email.toLowerCase().trim());
            const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
            const hashArray = Array.from(new Uint8Array(hashBuffer));
            const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
            return hashHex.substring(0, 16);
        }

        // Enviar formulario de bienvenida
        async function submitWelcome(event) {
            event.preventDefault();

            const name = document.getElementById('user-name').value.trim();
            const email = document.getElementById('user-email').value.trim();
            const submitBtn = event.target.querySelector('.welcome-btn');

            if (!name || !email || !email.includes('@')) {
                showError('Por favor, completa todos los campos correctamente');
                return;
            }

            submitBtn.classList.add('loading');
            submitBtn.querySelector('span').textContent = 'Creando tu acceso';

            try {
                const userCode = await hashEmail(email);

                localStorage.setItem('userName', name);
                localStorage.setItem('userEmail', email);
                localStorage.setItem('attendeeCode', userCode);

                // TODO: Guardar en Supabase
                // await supabaseClient.from('attendee_codes').insert({ code: userCode });

                submitBtn.querySelector('span').textContent = '¡Listo!';
                submitBtn.style.background = 'linear-gradient(135deg, #4CAF50 0%, #45a049 100%)';
                submitBtn.style.color = 'white';

                setTimeout(() => {
                    closeWelcomeOverlay();
                }, 800);

            } catch (error) {
                console.error('Error:', error);
                showError('Hubo un problema. Intenta nuevamente.');
                submitBtn.classList.remove('loading');
                submitBtn.querySelector('span').textContent = 'Comenzar experiencia';
            }
        }

        // Mostrar modo recuperación
        function showRecoveryMode(event) {
            event.preventDefault();

            const container = document.getElementById('welcome-container');
            container.classList.add('recovery-mode');

            container.innerHTML = `
                <div class="welcome-icon">
                    <span>🔑</span>
                </div>
                <h1 class="welcome-title">Recuperar Sesión</h1>
                <p class="welcome-subtitle">Introduce los mismos datos que usaste antes</p>

                <div id="error-container"></div>

                <form class="welcome-form" onsubmit="recoverSession(event)">
                    <div class="input-group with-icon">
                        <span class="input-icon">👤</span>
                        <input type="text" id="recover-name" placeholder="Tu nombre" required>
                    </div>

                    <div class="input-group with-icon">
                        <span class="input-icon">📧</span>
                        <input type="email" id="recover-email" placeholder="tu@email.com" required>
                    </div>

                    <button type="submit" class="welcome-btn">
                        <span>Recuperar sesión</span>
                    </button>
                </form>

                <div class="back-to-welcome">
                    <a href="#" onclick="location.reload()">
                        ← Volver a crear nueva sesión
                    </a>
                </div>
            `;
        }

        // Recuperar sesión
        async function recoverSession(event) {
            event.preventDefault();

            const name = document.getElementById('recover-name').value.trim();
            const email = document.getElementById('recover-email').value.trim();
            const submitBtn = event.target.querySelector('.welcome-btn');

            submitBtn.classList.add('loading');
            submitBtn.querySelector('span').textContent = 'Verificando';

            try {
                const userCode = await hashEmail(email);

                // TODO: Verificar en Supabase
                // const { data } = await supabaseClient.from('attendee_codes').select('code').eq('code', userCode).single();

                localStorage.setItem('userName', name);
                localStorage.setItem('userEmail', email);
                localStorage.setItem('attendeeCode', userCode);

                submitBtn.querySelector('span').textContent = '¡Bienvenido de nuevo!';
                submitBtn.style.background = 'linear-gradient(135deg, #4CAF50 0%, #45a049 100%)';
                submitBtn.style.color = 'white';

                setTimeout(() => {
                    closeWelcomeOverlay();
                }, 800);

            } catch (error) {
                console.error('Error:', error);
                showError('No encontramos tu registro. Verifica tus datos.');
                submitBtn.classList.remove('loading');
                submitBtn.querySelector('span').textContent = 'Recuperar sesión';
            }
        }

        // Cerrar overlay con animación
        function closeWelcomeOverlay() {
            const overlay = document.getElementById('welcome-overlay');
            const canvas = document.getElementById('particles-canvas');

            overlay.classList.add('fade-out');

            setTimeout(() => {
                overlay.style.display = 'none';
                canvas.style.display = 'none';
                showUserGreeting();
            }, 1000);
        }

        // Mostrar saludo personalizado
        function showUserGreeting() {
            const userName = localStorage.getItem('userName');
            const userCode = localStorage.getItem('attendeeCode');

            if (userName && userCode) {
                const container = document.getElementById('user-greeting-container');
                const textElement = document.getElementById('user-greeting-text');
                const badgeElement = document.getElementById('user-code-badge');

                if (container && textElement && badgeElement) {
                    textElement.textContent = `¡Hola, ${userName}!`;
                    badgeElement.textContent = `Código: ${userCode}`;
                    container.style.display = 'block';
                }
            }
        }

        // Mostrar error
        function showError(message) {
            const container = document.getElementById('error-container');
            if (container) {
                container.innerHTML = `<div class="error-message">⚠️ ${message}</div>`;
                setTimeout(() => {
                    container.innerHTML = '';
                }, 4000);
            }
        }

        // Cerrar sesión
        function logout() {
            if (confirm('¿Seguro que quieres cerrar tu sesión?')) {
                localStorage.removeItem('userName');
                localStorage.removeItem('userEmail');
                localStorage.removeItem('attendeeCode');
                localStorage.removeItem('userTags');
                location.reload();
            }
        }

        // ==================== FIN SISTEMA DE BIENVENIDA ====================

EOF

echo "✅ Funciones JavaScript creadas"

# Insertar JavaScript antes del último </script>
echo "📝 Insertando JavaScript en index.html..."
perl -i -0777 -pe 's{(    </script>\s*</body>)}{`cat welcome-js.tmp`\n$1}s' index.html
echo "✅ JavaScript insertado"

# Modificar window.onload para verificar sesión
echo "⚙️ Modificando window.onload..."
perl -i -pe 's{(window\.onload = async function\(\) \{)}{$1\n            // Verificar sesión existente\n            checkExistingSession();}' index.html

# Agregar la función checkExistingSession antes de window.onload
cat > check-session.tmp << 'EOF'

        // Verificar si ya hay sesión al cargar
        function checkExistingSession() {
            const userName = localStorage.getItem('userName');
            const userEmail = localStorage.getItem('userEmail');

            if (userName && userEmail) {
                // Usuario ya tiene sesión, mostrar saludo
                showUserGreeting();
                const logoutBtn = document.getElementById('logout-btn');
                if (logoutBtn) logoutBtn.style.display = 'block';
            } else {
                // No hay sesión, mostrar overlay
                const overlay = document.getElementById('welcome-overlay');
                const canvas = document.getElementById('particles-canvas');
                if (overlay) overlay.style.display = 'flex';
                if (canvas) canvas.style.display = 'block';
            }
        }
EOF

perl -i -0777 -pe 's{(// Cargar datos al iniciar\s+window\.onload)}{`cat check-session.tmp`\n\n$1}s' index.html

echo "✅ window.onload modificado"

# Limpiar archivos temporales
echo "🧹 Limpiando archivos temporales..."
rm -f welcome-styles.tmp welcome-html.tmp user-greeting.tmp welcome-js.tmp check-session.tmp

echo ""
echo "✅ ¡Integración completada exitosamente!"
echo ""
echo "📋 Resumen:"
echo "  ✓ CSS de bienvenida integrado"
echo "  ✓ HTML del overlay añadido"
echo "  ✓ Saludo personalizado añadido"
echo "  ✓ JavaScript integrado"
echo "  ✓ Sistema de sesión configurado"
echo ""
echo "🔍 Backups disponibles:"
ls -lh index.html.backup* 2>/dev/null || echo "  (ninguno previo)"
echo ""
echo "🚀 Puedes abrir index.html en tu navegador para probarlo"
echo ""
