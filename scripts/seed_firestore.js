// Script de seed único: lê os JSONs de assets existentes (hotel_1, hotel_2)
// e escreve no Firestore no formato que o FirestoreTenantRepository espera.
//
// Uso: node scripts/seed_firestore.js
//
// Requer que as regras do Firestore permitam escrita em /hotels/** e
// /konektoBrand/** temporariamente (veja firestore.rules.seed-temp.rules,
// aplicado e revertido automaticamente por scripts/run_seed.sh).

const fs = require('fs');
const path = require('path');
const { initializeApp } = require('firebase/app');
const { getFirestore, doc, setDoc } = require('firebase/firestore');

// Config pública (não sensível) copiada de apps/konekto_mobile/lib/firebase_options.dart (web).
const firebaseConfig = {
  apiKey: 'AIzaSyDbecwuokHQ75FptjTBkG6bxtzcHsQ8SvE',
  appId: '1:108078243563:web:663a41ea734995c0d2e8ae',
  messagingSenderId: '108078243563',
  projectId: 'konekto-4ff14',
  authDomain: 'konekto-4ff14.firebaseapp.com',
  storageBucket: 'konekto-4ff14.firebasestorage.app',
};

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const ASSETS_ROOT = path.join(__dirname, '..', 'apps', 'konekto_mobile', 'assets');
const HOTELS_ROOT = path.join(ASSETS_ROOT, 'tenant_assets', 'hotels');

// Mapa: nome do arquivo JSON -> nome do documento em hotels/{hotelId}/content/{doc}
const CONTENT_FILES = {
  'guest_info.json': 'guestInfo',
  'services_page.json': 'servicesPage',
  'room_service_menu.json': 'roomService',
  'spa_services.json': 'spa',
  'spa_availability.json': 'spaAvailability',
  'restaurants.json': 'restaurants',
  'restaurant_availability.json': 'restaurantAvailability',
  'eventos_data.json': 'eventos',
  'event_availability.json': 'eventAvailability',
  'passeios_data.json': 'passeios',
  'passeios_availability.json': 'passeiosAvailability',
  'mapa_data.json': 'mapa',
};

function readJsonIfExists(filePath) {
  if (!fs.existsSync(filePath)) return null;
  return JSON.parse(fs.readFileSync(filePath, 'utf8'));
}

async function seedHotel(hotelId) {
  const hotelDir = path.join(HOTELS_ROOT, hotelId);
  const tenantConfig = readJsonIfExists(path.join(hotelDir, 'tenant_config.json'));
  if (!tenantConfig) {
    console.log(`  (pulando ${hotelId}: tenant_config.json não encontrado)`);
    return;
  }

  await setDoc(doc(db, 'hotels', hotelId), tenantConfig);
  console.log(`  hotels/${hotelId} <- tenant_config.json`);

  for (const [fileName, docName] of Object.entries(CONTENT_FILES)) {
    const content = readJsonIfExists(path.join(hotelDir, fileName));
    if (!content) {
      console.log(`  (${hotelId}: ${fileName} não existe, pulando content/${docName})`);
      continue;
    }
    await setDoc(doc(db, 'hotels', hotelId, 'content', docName), content);
    console.log(`  hotels/${hotelId}/content/${docName} <- ${fileName}`);
  }
}

async function seedGlobal() {
  const promotions = readJsonIfExists(path.join(ASSETS_ROOT, 'data', 'promotions.json'));
  if (promotions) {
    await setDoc(doc(db, 'konektoBrand', 'promotions'), promotions);
    console.log('  konektoBrand/promotions <- promotions.json');
  }
}

async function main() {
  console.log('Semeando Firestore (projeto konekto-4ff14)...');
  await seedGlobal();
  for (const hotelId of ['hotel_1', 'hotel_2']) {
    console.log(`Hotel: ${hotelId}`);
    await seedHotel(hotelId);
  }
  console.log('Concluído.');
  process.exit(0);
}

main().catch((err) => {
  console.error('Falha ao semear o Firestore:', err);
  process.exit(1);
});
