// Script temporal para insertar 500 etiquetas tecnológicas en Supabase
const fs = require('fs');
const https = require('https');

const supabaseUrl = 'https://dacpkbftkzwnpnhirgny.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhY3BrYmZ0a3p3bnBuaGlyZ255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMjIyMzMsImV4cCI6MjA3NTU5ODIzM30.fOIihFR2oiHSr5VWRrn5KczCZbf65Mdj7TE2kRXS6JQ';

// Leer el archivo SQL y parsear los datos
const sqlContent = fs.readFileSync('insert_500_tech_tags.sql', 'utf8');

// Extraer los VALUES de INSERT
const valuesMatch = sqlContent.match(/VALUES\s+([\s\S]*?)\s+ON CONFLICT/);
if (!valuesMatch) {
    console.error('No se pudo parsear el SQL');
    process.exit(1);
}

// Parsear las filas de valores
const valuesText = valuesMatch[1];
const rows = [];
let currentRow = '';
let inQuotes = false;
let quoteChar = '';

for (let i = 0; i < valuesText.length; i++) {
    const char = valuesText[i];

    if ((char === '"' || char === "'") && valuesText[i-1] !== '\\') {
        if (!inQuotes) {
            inQuotes = true;
            quoteChar = char;
        } else if (char === quoteChar) {
            inQuotes = false;
        }
    }

    if (char === ',' && !inQuotes && valuesText[i+1] === '\n') {
        // Fin de una fila
        rows.push(currentRow.trim());
        currentRow = '';
        i++; // Saltar el \n
        continue;
    }

    currentRow += char;
}

// Añadir la última fila
if (currentRow.trim()) {
    rows.push(currentRow.trim());
}

console.log(`Parseadas ${rows.length} filas de SQL`);

// Convertir cada fila a objeto JSON
const tags = rows.map(row => {
    // Eliminar paréntesis iniciales/finales
    row = row.replace(/^\(/, '').replace(/\)$/, '');

    // Parsear los valores
    const match = row.match(/^'([^']+)',\s*'([^']*)',\s*'([^']+)',\s*(NULL)$/);
    if (!match) {
        console.error('Error parseando fila:', row.substring(0, 100));
        return null;
    }

    return {
        name: match[1],
        description: match[2],
        color: match[3],
        created_by: null
    };
}).filter(tag => tag !== null);

console.log(`Convertidas ${tags.length} etiquetas a JSON`);

// Insertar en lotes de 50 para evitar límites de payload
const BATCH_SIZE = 50;
let insertedCount = 0;

async function insertBatch(batch, batchNumber) {
    return new Promise((resolve, reject) => {
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
                'Prefer': 'resolution=ignore-duplicates'
            }
        };

        const req = https.request(options, (res) => {
            let responseData = '';

            res.on('data', (chunk) => {
                responseData += chunk;
            });

            res.on('end', () => {
                if (res.statusCode === 201 || res.statusCode === 200) {
                    insertedCount += batch.length;
                    console.log(`✓ Lote ${batchNumber} insertado (${batch.length} etiquetas) - Total: ${insertedCount}`);
                    resolve();
                } else {
                    console.error(`✗ Error en lote ${batchNumber}:`, res.statusCode, responseData);
                    reject(new Error(`HTTP ${res.statusCode}`));
                }
            });
        });

        req.on('error', (error) => {
            console.error(`✗ Error de red en lote ${batchNumber}:`, error);
            reject(error);
        });

        req.write(data);
        req.end();
    });
}

async function insertAllTags() {
    console.log(`\nIniciando inserción de ${tags.length} etiquetas en lotes de ${BATCH_SIZE}...\n`);

    for (let i = 0; i < tags.length; i += BATCH_SIZE) {
        const batch = tags.slice(i, i + BATCH_SIZE);
        const batchNumber = Math.floor(i / BATCH_SIZE) + 1;

        try {
            await insertBatch(batch, batchNumber);
            // Pequeña pausa entre lotes para no sobrecargar
            await new Promise(resolve => setTimeout(resolve, 200));
        } catch (error) {
            console.error(`Error en lote ${batchNumber}, continuando...`);
        }
    }

    console.log(`\n✓ Proceso completado. ${insertedCount} etiquetas insertadas.`);

    // Verificar el total
    const verifyOptions = {
        hostname: 'dacpkbftkzwnpnhirgny.supabase.co',
        port: 443,
        path: '/rest/v1/tags?select=count',
        method: 'GET',
        headers: {
            'apikey': supabaseKey,
            'Authorization': `Bearer ${supabaseKey}`,
            'Prefer': 'count=exact'
        }
    };

    const verifyReq = https.request(verifyOptions, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
            const countMatch = res.headers['content-range']?.match(/\/(\d+)/);
            if (countMatch) {
                console.log(`\nTotal de etiquetas en BD: ${countMatch[1]}`);
            }
        });
    });

    verifyReq.end();
}

insertAllTags();
