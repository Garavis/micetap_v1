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

// Datos para sugerencias contextuales
const momento = {
  esVerano: () => {
    const mes = new Date().getMonth() + 1; // 0-11 -> 1-12
    return mes >= 6 && mes <= 9; // Junio a Septiembre en hemisferio norte
  },
  esInvierno: () => {
    const mes = new Date().getMonth() + 1;
    return mes === 12 || mes <= 3; // Diciembre a Marzo en hemisferio norte
  },
  esNoche: () => {
    const hora = new Date().getHours();
    return hora >= 20 || hora <= 6; // 8pm a 6am
  },
  esFinDeSemana: () => {
    const dia = new Date().getDay(); // 0-6 (Domingo-Sábado)
    return dia === 0 || dia === 6;
  }
};

async function registrarHistorico(deviceId, consumo) {
  try {
    await db.collection('dispositivos_historial').add({
      deviceId: deviceId,
      consumo: consumo,
      fecha: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`📊 Registro histórico guardado para ${deviceId}: ${consumo} kWh`);
  } catch (error) {
    console.error('Error al guardar registro histórico:', error);
  }
}
// Función mejorada para generar consumo con distribución balanceada
function generarConsumoAleatorio() {
  const random = Math.random();
  let consumo;
  
  if (random < DIST_CRITICAL) {
    consumo = UMBRAL_CRITICAL + Math.random() * 0.3;
  } else if (random < DIST_CRITICAL + DIST_WARNING) {
    consumo = UMBRAL_WARNING + Math.random() * (UMBRAL_CRITICAL - UMBRAL_WARNING);
  } else {
    consumo = 0.5 + Math.random() * (UMBRAL_WARNING - 0.5);
  }
  
  consumo += (Math.random() * 0.1 - 0.05);
  return Math.max(0.5, Math.min(3.5, +consumo.toFixed(5)));
}

// Función mejorada para crear sugerencias variadas
const crearSugerencia = async (deviceId, tipo, consumoPromedio) => {
  const sugerenciasRef = db.collection('sugerencias');
  
  // Variedad de mensajes según el tipo de alerta
  const mensajes = {
    critical: [
      {
        corto: "¡Alerta crítica de consumo!",
        descripcion: "Tu consumo energético ha alcanzado niveles críticos. Esto podría indicar un problema en tu instalación o un electrodoméstico defectuoso."
      },
      {
        corto: "Consumo excesivo detectado",
        descripcion: `Tu consumo actual de ${consumoPromedio.toFixed(2)} kWh está muy por encima de lo recomendado. Te sugerimos revisar aparatos de alto consumo como aires acondicionados o calefactores.`
      },
      {
        corto: "¡Pico de consumo detectado!",
        descripcion: "Se ha detectado un pico anormal en tu consumo energético. Verifica si hay electrodomésticos funcionando simultáneamente o alguno que esté fallando."
      },
      {
        corto: "Posible fuga eléctrica",
        descripcion: "El consumo sostenido en niveles críticos podría indicar una fuga eléctrica. Considera contactar a un electricista para una revisión de tu instalación."
      },
      {
        corto: "Riesgo de sobrecarga",
        descripcion: "El nivel de consumo actual pone en riesgo tu instalación eléctrica. Recomendamos distribuir mejor el uso de los aparatos para evitar sobrecargas."
      }
    ],
    warning: [
      {
        corto: "Consumo por encima del promedio",
        descripcion: "Tu consumo está por encima del promedio recomendado. Considera apagar los dispositivos que no estés utilizando."
      },
      {
        corto: "Optimiza tu consumo energético",
        descripcion: `Has estado consumiendo ${consumoPromedio.toFixed(2)} kWh en promedio. Revisa aparatos como refrigeradores, televisores en modo standby o cargadores conectados sin uso.`
      },
      {
        corto: "Aumento gradual detectado",
        descripcion: "Hemos notado un aumento gradual en tu consumo energético. Esto podría deberse al uso intensivo de ciertos electrodomésticos."
      },
      {
        corto: "Considera horarios de bajo consumo",
        descripcion: "Tu consumo está elevado. Recuerda que utilizar electrodomésticos en horarios de menor demanda (22:00-08:00) puede ayudar a reducir costos."
      },
      {
        corto: "Atención al consumo",
        descripcion: "Tu hogar está consumiendo más energía de lo habitual. Verifica si hay aparatos que puedan estar consumiendo más de lo esperado."
      }
    ],
    excellent: [
      {
        corto: "¡Excelente consumo energético!",
        descripcion: "Tu consumo se mantiene en niveles óptimos. ¡Sigue así para mantener un hogar eficiente!"
      },
      {
        corto: "Consumo eficiente detectado",
        descripcion: `Con un consumo promedio de ${consumoPromedio.toFixed(2)} kWh, estás haciendo un uso eficiente de la energía. ¡Felicitaciones!`
      },
      {
        corto: "Ahorro energético notable",
        descripcion: "Tu patrón de consumo muestra un uso responsable de la energía. Esto se traduce en ahorro económico y menor impacto ambiental."
      }
    ]
  };
  
  // Consejos generales para todas las estaciones
  const consejosGenerales = [
    "Reemplazar bombillas tradicionales por LED puede reducir hasta un 80% el consumo en iluminación.",
    "Desconectar los electrodomésticos en lugar de dejarlos en standby puede ahorrar hasta un 10% en tu factura.",
    "Los electrodomésticos con etiqueta energética A+++ consumen hasta un 80% menos.",
    "El mantenimiento regular de tus electrodomésticos mejora su eficiencia y reduce el consumo.",
    "Utilizar regletas con interruptor facilita apagar completamente varios dispositivos a la vez.",
    "Revisar regularmente el medidor puede ayudarte a identificar picos de consumo inesperados."
  ];
  
  // Consejos estacionales
  const consejosVerano = [
    "Mantener el aire acondicionado a 24°C es económico y confortable.",
    "Usar ventiladores en lugar de aire acondicionado puede reducir significativamente tu consumo.",
    "Cerrar persianas durante las horas de mayor sol reduce la necesidad de refrigeración.",
    "Programar el aire acondicionado para que se apague durante la noche puede generar ahorros importantes."
  ];
  
  const consejosInvierno = [
    "Mantener la calefacción entre 19-21°C proporciona confort con consumo moderado.",
    "Usar burletes en puertas y ventanas evita fugas de calor y reduce el consumo.",
    "Programar la calefacción para que disminuya durante la noche ahorra energía.",
    "Ventilar la casa 10 minutos al día es suficiente para renovar el aire sin perder mucho calor."
  ];
  
  const consejosNocturnos = [
    "Aprovecha las tarifas nocturnas para poner electrodomésticos como lavadoras y lavavajillas.",
    "Reducir la iluminación en zonas no utilizadas de la casa disminuye el consumo.",
    "Utilizar temporizadores para apagar dispositivos durante la noche evita consumos innecesarios."
  ];
  
  const consejosFinSemana = [
    "Aprovecha la luz natural del fin de semana para reducir la iluminación artificial.",
    "Si vas a salir durante el fin de semana, recuerda desconectar los principales electrodomésticos.",
    "El fin de semana es buen momento para revisar y ajustar la programación de tus dispositivos inteligentes."
  ];
  
  // Seleccionar mensaje aleatorio según el tipo
  const mensajesDelTipo = mensajes[tipo] || mensajes.warning;
  const mensajeSeleccionado = mensajesDelTipo[Math.floor(Math.random() * mensajesDelTipo.length)];
  
  // Crear pool de consejos según el contexto temporal
  let poolConsejos = [...consejosGenerales];
  
  if (momento.esVerano()) {
    poolConsejos.push(...consejosVerano);
  }
  
  if (momento.esInvierno()) {
    poolConsejos.push(...consejosInvierno);
  }
  
  if (momento.esNoche()) {
    poolConsejos.push(...consejosNocturnos);
  }
  
  if (momento.esFinDeSemana()) {
    poolConsejos.push(...consejosFinSemana);
  }
  
  // Para algunos mensajes, añadir un consejo aleatorio (70% de probabilidad)
  let descripcionFinal = mensajeSeleccionado.descripcion;
  if (Math.random() > 0.3) {
    const consejoAleatorio = poolConsejos[Math.floor(Math.random() * poolConsejos.length)];
    descripcionFinal += "\n\nConsejo: " + consejoAleatorio;
  }
  
  // Crear la sugerencia en Firestore
  await sugerenciasRef.add({
    deviceId,
    tipoAlerta: tipo,
    mensajeCorto: mensajeSeleccionado.corto,
    descripcion: descripcionFinal,
    fecha: admin.firestore.Timestamp.now(),
    consumoRelacionado: consumoPromedio,
    leido: false,  // Campo para controlar si el usuario ha leído la sugerencia
    contexto: {
      esVerano: momento.esVerano(),
      esInvierno: momento.esInvierno(),
      esNoche: momento.esNoche(),
      esFinDeSemana: momento.esFinDeSemana()
    }
  });
  
  console.log(`💡 Sugerencia creada para ${deviceId}: ${mensajeSeleccionado.corto}`);
};

function clasificarConsumo(consumo) {
  if (consumo >= UMBRAL_CRITICAL) {
    return { tipo: 'critical', mensaje: '⚠️ Consumo extremadamente alto' };
  } else if (consumo >= UMBRAL_WARNING) {
    return { tipo: 'warning', mensaje: '🔶 Consumo superior al normal' };
  } else {
    return { tipo: 'excellent', mensaje: '✅ Consumo dentro del rango ideal' };
  }
}

function obtenerAlertaPredominante(deviceId) {
  const alertas = alertasTemporales[deviceId] || [];
  if (alertas.length === 0) return null;

  const conteo = { 'critical': 0, 'warning': 0, 'excellent': 0 };
  alertas.forEach(alerta => { conteo[alerta.tipo]++; });

  let tipoPredominante;
  if (conteo.critical >= alertas.length / 3) {
    tipoPredominante = 'critical';
  } else if (conteo.warning > conteo.excellent) {
    tipoPredominante = 'warning';
  } else {
    tipoPredominante = 'excellent';
  }

  let mensaje = {
    'critical': 'Consumo crítico',
    'warning': 'Consumo elevado',
    'excellent': 'Consumo estable'
  }[tipoPredominante];

  return {
    tipo: tipoPredominante,
    mensaje,
    consumoPromedio: alertas.reduce((sum, a) => sum + a.consumo, 0) / alertas.length,
    consumoMaximo: Math.max(...alertas.map(a => a.consumo)),
    detalles: conteo
  };
}

function generarConsumoConTendencia(deviceId) {
  if (!alertasTemporales[deviceId] || alertasTemporales[deviceId].length === 0) {
    return generarConsumoAleatorio();
  }

  const ultimoConsumo = alertasTemporales[deviceId][0].consumo;
  if (Math.random() < 0.2) {
    let nuevoConsumo = ultimoConsumo + (Math.random() * 0.3 - 0.15);
    return +Math.max(0.5, Math.min(3.5, nuevoConsumo)).toFixed(5);
  } else {
    return generarConsumoAleatorio();
  }
}



async function actualizarConsumo() {
  try {
    const snapshot = await dispositivosRef.get();
    for (const doc of snapshot.docs) {
      const deviceId = doc.id;

      if (!alertasTemporales[deviceId]) {
        alertasTemporales[deviceId] = [];
      }

      const nuevoConsumo = generarConsumoConTendencia(deviceId);
      await dispositivosRef.doc(deviceId).update({
        consumo: nuevoConsumo,
        ultimaActualizacion: admin.firestore.FieldValue.serverTimestamp()
      });
      
      await registrarHistorico(deviceId, nuevoConsumo);
      const clasificacion = clasificarConsumo(nuevoConsumo);
      alertasTemporales[deviceId].unshift({
        ...clasificacion,
        consumo: nuevoConsumo,
        timestamp: Date.now()
      });

      if (alertasTemporales[deviceId].length > MAX_ALERTAS_AGRUPADAS) {
        alertasTemporales[deviceId] = alertasTemporales[deviceId].slice(0, MAX_ALERTAS_AGRUPADAS);
      }

      const emoji = { critical: '🔴', warning: '🟠', excellent: '🟢' }[clasificacion.tipo] || '⚪';
      console.log(`${emoji} ${deviceId} → ${nuevoConsumo.toFixed(2)} kWh → ${clasificacion.tipo}`);
    }
  } catch (error) {
    console.error('Error al actualizar consumo:', error);
  }
}

async function procesarAlertas() {
  try {
    const snapshot = await dispositivosRef.get();
    const dispositivos = snapshot.docs.map(doc => doc.id);
    console.log("\n===== PROCESANDO ALERTAS AGRUPADAS =====");

    for (const deviceId of dispositivos) {
      const alertaPredominante = obtenerAlertaPredominante(deviceId);
      if (alertaPredominante) {
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

        const emoji = { critical: '🚨', warning: '⚠️', excellent: '✅' }[alertaPredominante.tipo] || '📝';
        console.log(`${emoji} Alerta enviada para ${deviceId}: ${alertaPredominante.tipo}`);
        console.log(`   → ${alertaPredominante.mensaje}`);
        console.log(`   → Consumo promedio: ${alertaPredominante.consumoPromedio.toFixed(2)} kWh`);

        // Crear sugerencias con mensajes variados
        if (alertaPredominante.tipo === "critical" || alertaPredominante.tipo === "warning") {
          await crearSugerencia(deviceId, alertaPredominante.tipo, alertaPredominante.consumoPromedio);
        } 
        // Ocasionalmente crear sugerencias positivas para consumo excelente (1 de cada 3 veces)
        else if (alertaPredominante.tipo === "excellent" && Math.random() < 0.33) {
          await crearSugerencia(deviceId, "excellent", alertaPredominante.consumoPromedio);
        }

        alertasTemporales[deviceId] = [];
      }
    }

    console.log("=======================================\n");
  } catch (error) {
    console.error('Error al procesar alertas:', error);
  }
}

// Función para limpiar sugerencias antiguas (opcional, ejecutar periódicamente)
async function limpiarSugerenciasAntiguas() {
  try {
    // Calcular fecha límite (por ejemplo, 7 días atrás)
    const limitDate = admin.firestore.Timestamp.fromDate(
      new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    );
    
    const snapshot = await db.collection('sugerencias')
      .where('fecha', '<', limitDate)
      .get();
      
    console.log(`🧹 Limpiando ${snapshot.docs.length} sugerencias antiguas...`);
    
    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    await batch.commit();
    console.log(`✅ Sugerencias antiguas eliminadas correctamente.`);
  } catch (error) {
    console.error('Error al limpiar sugerencias antiguas:', error);
  }
}

function probarDistribucion(iteraciones = 1000) {
  const resultados = { critical: 0, warning: 0, excellent: 0 };
  for (let i = 0; i < iteraciones; i++) {
    const consumo = generarConsumoAleatorio();
    const clasificacion = clasificarConsumo(consumo);
    resultados[clasificacion.tipo]++;
  }

  console.log(`\n🧪 PRUEBA DE DISTRIBUCIÓN (${iteraciones} iteraciones):`);
  console.log(`   Critical: ${resultados.critical}`);
  console.log(`   Warning: ${resultados.warning}`);
  console.log(`   Excellent: ${resultados.excellent}\n`);
}

probarDistribucion(1000);
console.log(`🚀 Iniciando simulador de consumo (actualización cada ${INTERVALO_SIMULACION / 1000} segundos)`);
setInterval(actualizarConsumo, INTERVALO_SIMULACION);
console.log(`📮 Procesamiento de alertas agrupadas cada ${INTERVALO_ALERTAS / 1000} segundos`);
setInterval(procesarAlertas, INTERVALO_ALERTAS);

// Ejecutar limpieza de sugerencias antiguas una vez al día
const INTERVALO_LIMPIEZA = 24 * 60 * 60 * 1000; // 24 horas
console.log(`🧹 Programando limpieza de sugerencias antiguas cada 24 horas`);
setInterval(limpiarSugerenciasAntiguas, INTERVALO_LIMPIEZA);

// Iniciar simulación
actualizarConsumo();
setTimeout(procesarAlertas, 5000);