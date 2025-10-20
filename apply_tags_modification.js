// Aplicar modificación a la tabla tags usando Supabase SQL API
const https = require('https');
const fs = require('fs');

const supabaseUrl = 'https://dacpkbftkzwnpnhirgny.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRhY3BrYmZ0a3p3bnBuaGlyZ255Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAwMjIyMzMsImV4cCI6MjA3NTU5ODIzM30.fOIihFR2oiHSr5VWRrn5KczCZbf65Mdj7TE2kRXS6JQ';

console.log('⚠️  IMPORTANTE: Este script requiere permisos de administrador en Supabase.');
console.log('⚠️  Por favor, ejecuta el siguiente SQL manualmente en el SQL Editor de Supabase:\n');

const sqlScript = fs.readFileSync('modify_tags_table.sql', 'utf8');
console.log('─'.repeat(70));
console.log(sqlScript);
console.log('─'.repeat(70));

console.log('\n📝 Pasos:');
console.log('1. Ve a tu proyecto Supabase: https://supabase.com/dashboard/project/dacpkbftkzwnpnhirgny');
console.log('2. Haz clic en "SQL Editor" en el menú lateral');
console.log('3. Copia y pega el SQL de arriba');
console.log('4. Haz clic en "Run" para ejecutar');
console.log('5. Una vez ejecutado, ejecuta: node insert_repeated_tags.js\n');
