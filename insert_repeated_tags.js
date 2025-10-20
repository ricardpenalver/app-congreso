// Script para insertar etiquetas con diferentes niveles de repetición
// Esto simula que múltiples usuarios han marcado las mismas palabras clave
const https = require('https');

const supabaseUrl = 'https://dacpkbftkzwnpnhirgny.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhY3BrYmZ0a3p3bnBuaGlyZ255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMjIyMzMsImV4cCI6MjA3NTU5ODIzM30.fOIihFR2oiHSr5VWRrn5KczCZbf65Mdj7TE2kRXS6JQ';

// Definir etiquetas con su frecuencia (cuántas veces se repite)
// Frecuencias: muy alta (100+), alta (50-99), media (20-49), baja (10-19), muy baja (5-9)
const tagsWithFrequency = [
    // Muy alta frecuencia (temas principales del congreso)
    { name: 'Inteligencia Artificial', count: 150, color: '#FF6F00' },
    { name: 'Machine Learning', count: 145, color: '#E65100' },
    { name: 'Deep Learning', count: 130, color: '#FF6D00' },
    { name: 'Innovación', count: 125, color: '#FF6B6B' },
    { name: 'Transformación Digital', count: 120, color: '#4ECDC4' },
    { name: 'Big Data', count: 115, color: '#45B7D1' },
    { name: 'Cloud Computing', count: 110, color: '#0089D6' },
    { name: 'Ciberseguridad', count: 105, color: '#FF0000' },
    { name: 'Sostenibilidad', count: 100, color: '#4CAF50' },

    // Alta frecuencia (temas importantes)
    { name: 'Python', count: 95, color: '#3776AB' },
    { name: 'JavaScript', count: 90, color: '#F7DF1E' },
    { name: 'Blockchain', count: 85, color: '#F7931A' },
    { name: 'IoT', count: 80, color: '#00ADD8' },
    { name: 'DevOps', count: 78, color: '#FF6B00' },
    { name: 'Análisis de Datos', count: 75, color: '#2196F3' },
    { name: 'APIs', count: 72, color: '#00D9FF' },
    { name: 'Microservicios', count: 70, color: '#4CAF50' },
    { name: 'Automatización', count: 68, color: '#FF9800' },
    { name: 'Kubernetes', count: 65, color: '#326CE5' },
    { name: 'Docker', count: 63, color: '#2496ED' },
    { name: 'React', count: 60, color: '#61DAFB' },
    { name: 'TensorFlow', count: 58, color: '#FF6F00' },
    { name: 'PostgreSQL', count: 55, color: '#336791' },
    { name: 'AWS', count: 53, color: '#FF9900' },
    { name: 'Azure', count: 50, color: '#0089D6' },

    // Frecuencia media (temas relevantes)
    { name: 'Node.js', count: 48, color: '#339933' },
    { name: 'TypeScript', count: 46, color: '#3178C6' },
    { name: 'Vue.js', count: 44, color: '#4FC08D' },
    { name: 'Angular', count: 42, color: '#DD0031' },
    { name: 'MongoDB', count: 40, color: '#47A248' },
    { name: 'Redis', count: 38, color: '#DC382D' },
    { name: 'GraphQL', count: 36, color: '#E10098' },
    { name: 'REST', count: 35, color: '#FF6C37' },
    { name: 'Git', count: 34, color: '#F05032' },
    { name: 'CI/CD', count: 33, color: '#2088FF' },
    { name: 'Agile', count: 32, color: '#0052CC' },
    { name: 'Scrum', count: 31, color: '#009FDA' },
    { name: 'Testing', count: 30, color: '#25A162' },
    { name: 'Arquitectura', count: 29, color: '#5C2D91' },
    { name: 'UX/UI', count: 28, color: '#FF61F6' },
    { name: 'Responsive', count: 27, color: '#3DDC84' },
    { name: 'Progressive Web Apps', count: 26, color: '#5A0FC8' },
    { name: 'Serverless', count: 25, color: '#FD5750' },
    { name: 'Edge Computing', count: 24, color: '#0066CC' },
    { name: 'Realidad Aumentada', count: 23, color: '#FF6B6B' },
    { name: 'Web3', count: 22, color: '#F16822' },
    { name: 'NFT', count: 21, color: '#000000' },
    { name: 'DeFi', count: 20, color: '#627EEA' },

    // Frecuencia baja (temas específicos)
    { name: 'Flutter', count: 19, color: '#02569B' },
    { name: 'Swift', count: 18, color: '#FA7343' },
    { name: 'Kotlin', count: 17, color: '#0095D5' },
    { name: 'Go', count: 16, color: '#00ADD8' },
    { name: 'Rust', count: 15, color: '#000000' },
    { name: 'Django', count: 14, color: '#092E20' },
    { name: 'Flask', count: 14, color: '#000000' },
    { name: 'Laravel', count: 13, color: '#FF2D20' },
    { name: 'Spring Boot', count: 13, color: '#6DB33F' },
    { name: 'Next.js', count: 12, color: '#000000' },
    { name: 'Tailwind CSS', count: 12, color: '#06B6D4' },
    { name: 'Svelte', count: 11, color: '#FF3E00' },
    { name: 'Solid.js', count: 11, color: '#2C4F7C' },
    { name: 'Astro', count: 10, color: '#FF5D01' },
    { name: 'Remix', count: 10, color: '#3992FF' },

    // Muy baja frecuencia (temas emergentes o nicho)
    { name: 'WebAssembly', count: 9, color: '#654FF0' },
    { name: 'Deno', count: 9, color: '#000000' },
    { name: 'Bun', count: 8, color: '#FBF0DF' },
    { name: 'Quantum Computing', count: 8, color: '#6929C4' },
    { name: 'Edge AI', count: 7, color: '#4CAF50' },
    { name: 'Federated Learning', count: 7, color: '#3F51B5' },
    { name: 'MLOps', count: 7, color: '#FF6F00' },
    { name: 'DataOps', count: 6, color: '#2196F3' },
    { name: 'GitOps', count: 6, color: '#F05032' },
    { name: 'FinOps', count: 6, color: '#FF9900' },
    { name: 'Observabilidad', count: 6, color: '#F46800' },
    { name: 'Chaos Engineering', count: 5, color: '#FF5722' },
    { name: 'Service Mesh', count: 5, color: '#466BB0' },
    { name: 'WebRTC', count: 5, color: '#333333' },
    { name: 'WebGPU', count: 5, color: '#005A9C' },
    { name: 'HTMX', count: 5, color: '#3D72D7' },
    { name: 'Alpine.js', count: 5, color: '#8BC0D0' },
    { name: 'Qwik', count: 5, color: '#AC7EF4' },
    { name: 'Solid', count: 5, color: '#2C4F7C' },
    { name: 'Fresh', count: 5, color: '#FFDB1E' },
];

// Primero, limpiar la tabla de tags existente
async function clearTags() {
    return new Promise((resolve, reject) => {
        const options = {
            hostname: 'dacpkbftkzwnpnhirgny.supabase.co',
            port: 443,
            path: '/rest/v1/tags?select=*',
            method: 'DELETE',
            headers: {
                'apikey': supabaseKey,
                'Authorization': `Bearer ${supabaseKey}`,
                'Prefer': 'return=minimal'
            }
        };

        const req = https.request(options, (res) => {
            console.log(`✓ Tabla tags limpiada (status: ${res.statusCode})`);
            resolve();
        });

        req.on('error', reject);
        req.end();
    });
}

// Insertar etiquetas con repeticiones
async function insertRepeatedTags() {
    console.log('Preparando inserción de etiquetas con repeticiones...\n');

    const allTags = [];

    // Crear múltiples registros de cada etiqueta según su frecuencia
    for (const tag of tagsWithFrequency) {
        for (let i = 0; i < tag.count; i++) {
            allTags.push({
                name: tag.name,
                description: `Mencionada ${tag.count} veces por los asistentes`,
                color: tag.color,
                created_by: null
            });
        }
    }

    console.log(`Total de registros a insertar: ${allTags.length}`);
    console.log(`Etiquetas únicas: ${tagsWithFrequency.length}\n`);

    // Insertar en lotes de 100
    const BATCH_SIZE = 100;
    let insertedCount = 0;

    for (let i = 0; i < allTags.length; i += BATCH_SIZE) {
        const batch = allTags.slice(i, i + BATCH_SIZE);
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;

        await new Promise((resolve, reject) => {
            const data = JSON.stringify(batch);

            const options = {
                hostname: 'dacpkbftkzwnpnhirgny.supabase.co',
                port: 443,
                path: '/rest/v1/tags',
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'apikey': supabaseKey,
                    'Authorization': `Bearer ${supabaseKey}`,
                    'Prefer': 'return=minimal'
                }
            };

            const req = https.request(options, (res) => {
                if (res.statusCode === 201 || res.statusCode === 200) {
                    insertedCount += batch.length;
                    console.log(`✓ Lote ${batchNumber}/${Math.ceil(allTags.length / BATCH_SIZE)} insertado (${batch.length} registros) - Total: ${insertedCount}/${allTags.length}`);
                    resolve();
                } else {
                    console.error(`✗ Error en lote ${batchNumber}: HTTP ${res.statusCode}`);
                    resolve(); // Continuar aunque haya error
                }
            });

            req.on('error', (error) => {
                console.error(`✗ Error de red en lote ${batchNumber}:`, error.message);
                resolve();
            });

            req.write(data);
            req.end();
        });

        // Pequeña pausa entre lotes
        await new Promise(resolve => setTimeout(resolve, 300));
    }

    console.log(`\n✓ Proceso completado. ${insertedCount} registros insertados.`);

    // Mostrar resumen de frecuencias
    console.log('\n📊 Resumen de frecuencias:');
    console.log('─────────────────────────────────────');
    const topTags = tagsWithFrequency.slice(0, 10);
    topTags.forEach((tag, index) => {
        console.log(`${index + 1}. ${tag.name.padEnd(30)} ${tag.count} menciones`);
    });
}

async function run() {
    try {
        console.log('🗑️  Limpiando etiquetas existentes...\n');
        await clearTags();

        console.log('\n📝 Insertando nuevas etiquetas con repeticiones...\n');
        await insertRepeatedTags();

        console.log('\n✅ ¡Proceso completado! Ahora puedes ver la nube de etiquetas jerarquizada.\n');
    } catch (error) {
        console.error('❌ Error:', error);
    }
}

run();
