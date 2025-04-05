const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const dispositivosRef = db.collection('dispositivos');
const alertasRef = db.collection('alertas');

// Configuración
const INTERVALO_SIMULACION = 2000; // 2 segundos para actualizar consumo
const INTERVALO_ALERTAS = 30000;   // 30 segundos para enviar alertas agrupadas
const MAX_ALERTAS_AGRUPADAS = 15;  // Máximo de alertas a considerar en cada agrupación

// Distribución más equilibrada (pero aún con tendencia a críticas)
const DIST_CRITICAL = 0.25;  // 25% críticas
const DIST_WARNING = 0.35;   // 35% warnings
const DIST_EXCELLENT = 0.40; // 40% excelentes

// Umbrales de clasificación
const UMBRAL_CRITICAL = 3.2;
const UMBRAL_WARNING = 2.2;

// Almacenamiento temporal de alertas por dispositivo
const alertasTemporales = {};

// Función mejorada para generar consumo con distribución balanceada
function generarConsumoAleatorio() {
  const random = Math.random();
  let consumo;
  
  if (random < DIST_CRITICAL) {
    // Generar valores en el rango "critical" (3.2 - 3.5)
    consumo = UMBRAL_CRITICAL + Math.random() * 0.3;
  } else if (random < DIST_CRITICAL + DIST_WARNING) {
    // Generar valores en el rango "warning" (2.2 - 3.2)
    consumo = UMBRAL_WARNING + Math.random() * (UMBRAL_CRITICAL - UMBRAL_WARNING);
  } else {
    // Generar valores en el rango "excellent" (0.5 - 2.2)
    consumo = 0.5 + Math.random() * (UMBRAL_WARNING - 0.5);
  }
  
  // Añadir pequeña variación aleatoria para hacerlo más realista
  consumo += (Math.random() * 0.1 - 0.05); // ±0.05 variación
  
  return Math.max(0.5, Math.min(3.5, +consumo.toFixed(5))); // Asegurar que esté entre 0.5 y 3.5
}

function clasificarConsumo(consumo) {
  if (consumo >= UMBRAL_CRITICAL) {
    return { tipo: 'critical', mensaje: '⚠️ Consumo extremadamente alto' };
  } else if (consumo >= UMBRAL_WARNING) {
    return { tipo: 'warning', mensaje: '🔶 Consumo superior al normal' };
  } else {
    return { tipo: 'excellent', mensaje: '✅ Consumo dentro del rango ideal' };
  }
}

// Determina la alerta predominante para un dispositivo
function obtenerAlertaPredominante(deviceId) {
  const alertas = alertasTemporales[deviceId] || [];
  
  if (alertas.length === 0) return null;
  
  // Contar las ocurrencias de cada tipo
  const conteo = {
    'critical': 0,
    'warning': 0,
    'excellent': 0
  };
  
  alertas.forEach(alerta => {
    conteo[alerta.tipo]++;
  });
  
  console.log(`📊 Dispositivo ${deviceId} - Conteo: Critical=${conteo.critical}, Warning=${conteo.warning}, Excellent=${conteo.excellent}`);
  
  // Determinar el tipo predominante basado en mayoría simple
  let tipoPredominante;
  
  // Priorizar critical si hay al menos 1/3 de alertas críticas
  if (conteo.critical >= alertas.length / 3) {
    tipoPredominante = 'critical';
  } 
  // Priorizar warning si hay más warnings que excellent
  else if (conteo.warning > conteo.excellent) {
    tipoPredominante = 'warning';
  }
  // De lo contrario, excellent es predominante
  else {
    tipoPredominante = 'excellent';
  }
  
  // Generar mensaje en base al tipo y conteo
  let mensaje;
  switch (tipoPredominante) {
    case 'critical':
      mensaje = `Consumo crítico`;
      break;
    case 'warning':
      mensaje = `Consumo elevada`;
      break;
    case 'excellent':
      mensaje = `Consumo estable`;
      break;
  }
  
  return {
    tipo: tipoPredominante,
    mensaje,
    consumoPromedio: alertas.reduce((sum, a) => sum + a.consumo, 0) / alertas.length,
    consumoMaximo: Math.max(...alertas.map(a => a.consumo)),
    detalles: conteo
  };
}

// Función para simular fluctuaciones en base al historial del dispositivo
function generarConsumoConTendencia(deviceId) {
  // Si no hay historial, generamos un consumo aleatorio normal
  if (!alertasTemporales[deviceId] || alertasTemporales[deviceId].length === 0) {
    return generarConsumoAleatorio();
  }
  
  // Obtener el último consumo del dispositivo
  const ultimoConsumo = alertasTemporales[deviceId][0].consumo;
  
  // Determinar la tendencia - 20% de las veces seguimos la tendencia, 80% generamos un valor nuevo
  if (Math.random() < 0.2) {
    // Continuamos la tendencia con una pequeña variación
    const variacion = (Math.random() * 0.3) - 0.15; // Entre -0.15 y +0.15
    let nuevoConsumo = ultimoConsumo + variacion;
    
    // Asegurarnos que está en el rango válido
    nuevoConsumo = Math.max(0.5, Math.min(3.5, nuevoConsumo));
    
    return +nuevoConsumo.toFixed(5);
  } else {
    // Valor completamente nuevo con distribución balanceada
    return generarConsumoAleatorio();
  }
}

// Actualiza el consumo pero guarda las alertas temporalmente
async function actualizarConsumo() {
  try {
    const snapshot = await dispositivosRef.get();
    
    for (const doc of snapshot.docs) {
      const deviceId = doc.id;
      
      // Inicializar array para este dispositivo si no existe
      if (!alertasTemporales[deviceId]) {
        alertasTemporales[deviceId] = [];
      }
      
      // Generamos un consumo con tendencia basada en historial
      const nuevoConsumo = generarConsumoConTendencia(deviceId);
      
      // Actualizar consumo en Firestore
      await dispositivosRef.doc(deviceId).update({ 
        consumo: nuevoConsumo,
        ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp()
      });
      
      // Clasificar el consumo
      const clasificacion = clasificarConsumo(nuevoConsumo);
      
      // Agregar nueva alerta al inicio del array
      alertasTemporales[deviceId].unshift({
        ...clasificacion,
        consumo: nuevoConsumo,
        timestamp: Date.now()
      });
      
      // Limitar el tamaño del array
      if (alertasTemporales[deviceId].length > MAX_ALERTAS_AGRUPADAS) {
        alertasTemporales[deviceId] = alertasTemporales[deviceId].slice(0, MAX_ALERTAS_AGRUPADAS);
      }
      
      // Determinar emoji según el tipo
      let emoji;
      switch(clasificacion.tipo) {
        case 'critical': emoji = '🔴'; break;
        case 'warning': emoji = '🟠'; break;
        case 'excellent': emoji = '🟢'; break;
        default: emoji = '⚪';
      }
      
      console.log(`${emoji} ${deviceId} → ${nuevoConsumo.toFixed(2)} kWh → ${clasificacion.tipo}`);
    }
  } catch (error) {
    console.error('Error al actualizar consumo:', error);
  }
}

// Procesa y envía las alertas agrupadas
async function procesarAlertas() {
  try {
    // Obtener todos los deviceIds
    const snapshot = await dispositivosRef.get();
    const dispositivos = snapshot.docs.map(doc => doc.id);
    
    console.log("\n===== PROCESANDO ALERTAS AGRUPADAS =====");
    
    for (const deviceId of dispositivos) {
      // Obtener la alerta predominante
      const alertaPredominante = obtenerAlertaPredominante(deviceId);
      
      // Si hay alertas para este dispositivo
      if (alertaPredominante) {
        // Añadir la alerta a Firestore
        await alertasRef.add({
          deviceId,
          tipo: alertaPredominante.tipo,
          mensaje: alertaPredominante.mensaje,
          consumoPromedio: alertaPredominante.consumoPromedio,
          consumoMaximo: alertaPredominante.consumoMaximo,
          detalles: alertaPredominante.detalles,
          fecha: admin.firestore.FieldValue.serverTimestamp(),
          muestras: alertasTemporales[deviceId].length
        });
        
        // Emoji para el tipo de alerta
        let emoji;
        switch(alertaPredominante.tipo) {
          case 'critical': emoji = '🚨'; break;
          case 'warning': emoji = '⚠️'; break;
          case 'excellent': emoji = '✅'; break;
          default: emoji = '📝';
        }
        
        console.log(`${emoji} Alerta enviada para ${deviceId}: ${alertaPredominante.tipo}`);
        console.log(`   → ${alertaPredominante.mensaje}`);
        console.log(`   → Consumo promedio: ${alertaPredominante.consumoPromedio.toFixed(2)} kWh`);
        
        // Limpiar las alertas temporales para este dispositivo
        alertasTemporales[deviceId] = [];
      }
    }
    
    console.log("=======================================\n");
  } catch (error) {
    console.error('Error al procesar alertas:', error);
  }
}

// Función para probar la distribución de valores
function probarDistribucion(iteraciones = 1000) {
  const resultados = { critical: 0, warning: 0, excellent: 0 };
  
  for (let i = 0; i < iteraciones; i++) {
    const consumo = generarConsumoAleatorio();
    const clasificacion = clasificarConsumo(consumo);
    resultados[clasificacion.tipo]++;
  }
  
  console.log(`\n🧪 PRUEBA DE DISTRIBUCIÓN (${iteraciones} iteraciones):`);
  console.log(`   Critical: ${resultados.critical} (${(resultados.critical/iteraciones*100).toFixed(1)}%)`);
  console.log(`   Warning: ${resultados.warning} (${(resultados.warning/iteraciones*100).toFixed(1)}%)`);
  console.log(`   Excellent: ${resultados.excellent} (${(resultados.excellent/iteraciones*100).toFixed(1)}%)`);
  console.log("");
}

// Iniciar con una prueba de distribución
probarDistribucion(1000);

// Iniciar actualizaciones de consumo (cada 2 segundos)
console.log(`🚀 Iniciando simulador de consumo (actualización cada ${INTERVALO_SIMULACION/1000} segundos)`);
console.log(`📊 Distribución objetivo: Critical=${DIST_CRITICAL*100}%, Warning=${DIST_WARNING*100}%, Excellent=${DIST_EXCELLENT*100}%`);
setInterval(actualizarConsumo, INTERVALO_SIMULACION);

// Iniciar envío de alertas agrupadas (cada 30 segundos)
console.log(`📮 Procesamiento de alertas agrupadas cada ${INTERVALO_ALERTAS/1000} segundos`);
setInterval(procesarAlertas, INTERVALO_ALERTAS);

// Ejecutar una vez al inicio
actualizarConsumo();
setTimeout(procesarAlertas, 5000);