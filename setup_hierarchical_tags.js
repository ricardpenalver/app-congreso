// Script completo para configurar etiquetas jerarquizadas
// Este script evita el problema de UNIQUE eliminando todas las tags primero
const https = require('https');

const supabaseUrl = 'https://dacpkbftkzwnpnhirgny.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhY3BrYmZ0a3p3bnBuaGlyZ255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMjIyMzMsImV4cCI6MjA3NTU5ODIzM30.fOIihFR2oiHSr5VWRrn5KczCZbf65Mdj7TE2kRXS6JQ';

// Etiquetas con frecuencias definidas
const tagsData = [
    // Muy alta frecuencia (temas principales)
    { name: 'Inteligencia Artificial', count: 150, color: '#FF6F00' },
    { name: 'Machine Learning', count: 145, color: '#E65100' },
    { name: 'Deep Learning', count: 130, color: '#FF6D00' },
    { name: 'Innovación', count: 125, color: '#FF6B6B' },
    { name: 'Transformación Digital', count: 120, color: '#4ECDC4' },
    { name: 'Big Data', count: 115, color: '#45B7D1' },
    { name: 'Cloud Computing', count: 110, color: '#0089D6' },
    { name: 'Ciberseguridad', count: 105, color: '#FF0000' },
    { name: 'Sostenibilidad', count: 100, color: '#4CAF50' },

    // Alta frecuencia
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

    // Frecuencia media
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
    { name: 'PWA', count: 26, color: '#5A0FC8' },
    { name: 'Serverless', count: 25, color: '#FD5750' },
    { name: 'Edge Computing', count: 24, color: '#0066CC' },
    { name: 'Realidad Aumentada', count: 23, color: '#FF6B6B' },
    { name: 'Web3', count: 22, color: '#F16822' },
    { name: 'NFT', count: 21, color: '#9C27B0' },
    { name: 'DeFi', count: 20, color: '#627EEA' },

    // Frecuencia baja
    { name: 'Flutter', count: 19, color: '#02569B' },
    { name: 'Swift', count: 18, color: '#FA7343' },
    { name: 'Kotlin', count: 17, color: '#0095D5' },
    { name: 'Go', count: 16, color: '#00ADD8' },
    { name: 'Rust', count: 15, color: '#CE412B' },
    { name: 'Django', count: 14, color: '#092E20' },
    { name: 'Flask', count: 14, color: '#010101' },
    { name: 'Laravel', count: 13, color: '#FF2D20' },
    { name: 'Spring Boot', count: 13, color: '#6DB33F' },
    { name: 'Next.js', count: 12, color: '#000000' },
    { name: 'Tailwind CSS', count: 12, color: '#06B6D4' },
    { name: 'Svelte', count: 11, color: '#FF3E00' },
    { name: 'Solid.js', count: 11, color: '#2C4F7C' },
    { name: 'Astro', count: 10, color: '#FF5D01' },
    { name: 'Remix', count: 10, color: '#3992FF' },

    // Muy baja frecuencia
    { name: 'WebAssembly', count: 9, color: '#654FF0' },
    { name: 'Deno', count: 9, color: '#222222' },
    { name: 'Bun', count: 8, color: '#F472B6' },
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
];

console.log('⚠️  ATENCIÓN: La tabla tags tiene una restricción UNIQUE en el campo "name".');
console.log('⚠️  Para permitir etiquetas repetidas, necesitas ejecutar esto en Supabase SQL Editor:\n');
console.log('ALTER TABLE tags DROP CONSTRAINT IF EXISTS tags_name_key;');
console.log('DROP INDEX IF EXISTS idx_tags_name;');
console.log('CREATE INDEX idx_tags_name ON tags(name);\n');
console.log('URL: https://supabase.com/dashboard/project/dacpkbftkzwnpnhirgny/sql/new\n');
console.log('Una vez hecho, presiona ENTER para continuar...');

// Esperar input del usuario
process.stdin.once('data', async () => {
    console.log('\n✓ Continuando con la inserción...\n');

    // Primero limpiar la tabla
    console.log('🗑️  Limpiando etiquetas existentes...');
    await deleteAllTags();

    // Luego insertar las nuevas con repeticiones
    console.log('\n📝 Insertando etiquetas con jerarquía...\n');
    await insertHierarchicalTags();

    process.exit(0);
});

async function deleteAllTags() {
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
            console.log(`✓ Tags eliminadas (HTTP ${res.statusCode})`);
            resolve();
        });

        req.on('error', (error) => {
            console.error('Error eliminando tags:', error.message);
            reject(error);
        });

        req.end();
    });
}

async function insertHierarchicalTags() {
    // Crear array con repeticiones
    const allTags = [];
    for (const tag of tagsData) {
        for (let i = 0; i < tag.count; i++) {
            allTags.push({
                name: tag.name,
                description: `Mencionada por ${tag.count} participantes`,
                color: tag.color,
                created_by: null
            });
        }
    }

    console.log(`Total de registros a insertar: ${allTags.length}`);
    console.log(`Etiquetas únicas: ${tagsData.length}\n`);

    // Insertar en lotes
    const BATCH_SIZE = 100;
    let insertedCount = 0;

    for (let i = 0; i < allTags.length; i += BATCH_SIZE) {
        const batch = allTags.slice(i, i + BATCH_SIZE);
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;
        const totalBatches = Math.ceil(allTags.length / BATCH_SIZE);

        const success = await insertBatch(batch);
        if (success) {
            insertedCount += batch.length;
            console.log(`✓ Lote ${batchNumber}/${totalBatches} (${batch.length} tags) - Total: ${insertedCount}/${allTags.length}`);
        } else {
            console.log(`✗ Error en lote ${batchNumber} - puede ser por restricción UNIQUE`);
        }

        await new Promise(resolve => setTimeout(resolve, 200));
    }

    console.log(`\n✅ Completado: ${insertedCount} registros insertados`);
    console.log(`\n📊 Top 10 etiquetas por frecuencia:`);
    tagsData.slice(0, 10).forEach((tag, i) => {
        console.log(`${i + 1}. ${tag.name.padEnd(30)} - ${tag.count} menciones`);
    });
}

async function insertBatch(batch) {
    return new Promise((resolve) => {
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
            resolve(res.statusCode === 201 || res.statusCode === 200);
        });

        req.on('error', () => resolve(false));
        req.write(data);
        req.end();
    });
}
