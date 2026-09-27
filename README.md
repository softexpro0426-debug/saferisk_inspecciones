# SafeRisk Inspecciones

Aplicación móvil para inspectores de SafeRisk. Permite consultar casos asignados y registrar su avance: **En camino → Llegada confirmada → Finalizada**. La inspección física se realiza fuera de la aplicación.

**Actualización:** 26 de septiembre de 2026 · America/Guayaquil  
**Versión:** 1.0.0+1  
**Plataformas presentes:** Android e iOS  
**Identificador Android:** ec.saferisk.saferisk_inspecciones

Esta documentación describe el código del repositorio. No implica certificación de compilación, publicación en tiendas ni validación funcional de todas las plataformas.

## Contenido

- [Funcionalidades](#funcionalidades)
- [Flujo de trabajo](#flujo-de-trabajo)
- [Tecnologías y requisitos](#tecnologías-y-requisitos)
- [Instalación y configuración](#instalación-y-configuración)
- [Arquitectura](#arquitectura)
- [Integraciones HTTP](#integraciones-http)
- [Persistencia y errores](#persistencia-y-errores)
- [Validación](#validación)
- [Compilación](#compilación)
- [Preparación para GitHub](#preparación-para-github)
- [Limitaciones conocidas](#limitaciones-conocidas)

## Funcionalidades

| Módulo | Implementación actual |
| --- | --- |
| Arranque | Splash de marca y recuperación de la sesión local. |
| Acceso | Usuario y contraseña, identificación de perfil y acceso operativo para inspectores. |
| Inicio | Indicadores de pendientes, pendientes de hoy, finalizadas, finalizadas de la semana y asignadas. |
| Inspecciones | Consulta y filtros por aseguradora, identificación, placa, nombre y número de caso. |
| Detalle | Asegurado, vehículo, contacto, fechas, estado y observaciones; acciones rápidas para placa y teléfono. |
| En camino | Registro de salida con coordenadas actuales mediante FlowConnect. |
| Llegada | Google Maps, ubicación actual, actualización y centrado del mapa; confirmación de llegada. |
| Finalización | Confirmación explícita del inspector y actualización mediante la API existente. |
| Actividad | Resumen de pendientes y finalizadas de hoy; lista independiente de actividad reciente desde FlowConnect. |
| Perfil | Usuario, conexión, versión, términos y condiciones y cierre de sesión. |

El acceso de Brokers presenta un diálogo con enlaces de tienda. Los destinos en [app_store_links.dart](lib/src/core/config/app_store_links.dart) contienen marcadores de posición y requieren configuración.

El flujo actual no incluye formularios de inspección, captura de fotos, carga de evidencias ni borradores.

## Flujo de trabajo

1. El inspector inicia sesión y abre una inspección asignada.
2. Revisa los datos y pulsa **En camino**. La aplicación obtiene ubicación y envía el seguimiento.
3. Al llegar, pulsa **Confirmar llegada**. Se envían coordenadas actuales y fecha.
4. Realiza el trabajo fuera de la aplicación.
5. Abre la finalización y confirma que la inspección terminó.

Las operaciones bloquean solicitudes simultáneas. Al reabrir un caso con llegada guardada, el flujo conduce a finalizar. Un caso finalizado localmente no vuelve a enviarse.

## Tecnologías y requisitos

| Elemento | Configuración |
| --- | --- |
| Flutter | SDK local utilizado durante la revisión: 3.41.5, canal stable; no hay un archivo que fije su versión. |
| Dart | Restricción declarada: ^3.11.3. |
| Estado | flutter_riverpod 3.x, Notifier y AsyncNotifier. |
| HTTP | Dio 5.x; clientes independientes para API principal y FlowConnect. |
| Navegación | GoRouter para rutas principales; Navigator para pantallas internas. |
| Sesión | flutter_secure_storage. |
| Progreso local | shared_preferences. |
| Ubicación | geolocator y google_maps_flutter. |
| Utilidades | connectivity_plus, intl, package_info_plus y url_launcher. |

Las restricciones exactas están en [pubspec.yaml](pubspec.yaml). [pubspec.lock](pubspec.lock) se versiona para conservar las dependencias resueltas.

**Android:** Flutter y Android SDK configurados, Java 17 compatible con el proyecto y Android SDK Platform 37. El proyecto usa compileSdk 37; minSdk, targetSdk y NDK se toman de Flutter.

**iOS:** macOS, Xcode y configuración de plugins y firma. La compilación iOS no se verificó durante esta preparación desde Windows.

## Instalación y configuración

### Obtener dependencias

Clonar el repositorio, entrar en su carpeta y ejecutar:

    flutter doctor
    flutter pub get

Los comandos de ejecución de este documento son instrucciones para preparar el entorno; no se ejecutaron como pruebas funcionales durante la documentación.

### FlowConnect

Copiar [config/example.json](config/example.json) a config/local.json y reemplazar el valor:

    {
      "FLOWCONNECT_API_KEY": "REEMPLAZAR_CON_CLAVE_AUTORIZADA"
    }

El archivo local está excluido de Git. Ejecutar la app con:

    flutter run --dart-define-from-file=config/local.json

También se admite --dart-define=FLOWCONNECT_API_KEY=... La aplicación ya no incluye una clave predeterminada en el código. Omitirla deja vacío el encabezado de FlowConnect y puede producir errores de autorización.

URL base centralizadas en [app_config.dart](lib/src/core/config/app_config.dart):

- API principal: https://sistema.saferisk.ec/SW_APP/
- FlowConnect: https://sistema.saferisk.ec/flowconnect/

### Google Maps en Android

Agregar a android/local.properties, conservando las rutas locales sdk.dir y flutter.sdk:

    MAPS_API_KEY=REEMPLAZAR_CON_CLAVE_ANDROID

Plantilla: [android/local.properties.example](android/local.properties.example). Gradle inyecta el valor en el manifest. La variable de entorno MAPS_API_KEY también se admite y tiene prioridad sobre la propiedad local.

### Google Maps en iOS

Copiar [ios/Flutter/Local.xcconfig.example](ios/Flutter/Local.xcconfig.example) a ios/Flutter/Local.xcconfig y completar:

    MAPS_API_KEY = REEMPLAZAR_CON_CLAVE_IOS

Debug y Release incluyen ese archivo. Info.plist expone el valor a AppDelegate para inicializar Google Maps.

Las claves deben tener habilitado el SDK correspondiente y restricciones para cada aplicación. Excluirlas de Git evita publicarlas en el código fuente, pero no impide extraerlas de un binario móvil.

### Permisos

El flujo usa ubicación actual para registrar salida y llegada. Verifica GPS activo y gestiona permisos denegados o bloqueados permanentemente.

Los archivos nativos aún declaran permisos heredados de cámara y galería, aunque el flujo no los utiliza. iOS también incluye una descripción de ubicación permanente; el código Dart obtiene posición actual, sin seguimiento continuo en segundo plano.

## Arquitectura

    lib/
      main.dart                  Inicializa Flutter y ProviderScope
      src/
        app/                     MaterialApp y rutas principales
        core/
          config/                URL base y enlaces de tienda
          location/              Servicio y providers de ubicación
          network/               Clientes HTTP y mensajes de error
          security/              Sesión segura y señal de expiración
          services/              Apertura de enlaces externos
          theme/                 Colores y tema
        features/
          activity/              Resumen y actividad reciente
          arrival/               Mapa y llegada
          auth/                  Acceso y sesión
          dashboard/             Indicadores
          inspection_form/       Finalización; conserva el nombre histórico
          inspections/           Casos, filtros y seguimiento
          main/                  Navegación inferior
          profile/               Perfil y términos
          splash/                Arranque

Los módulos separan responsabilidades según sus necesidades:

- **data:** fuentes remotas, DTO, repositorios y persistencia.
- **domain:** entidades y contratos de repositorio.
- **presentation:** páginas, widgets y controladores Riverpod.

La actividad reciente tiene fuente y controlador propios. No se construye mezclando pendientes y finalizadas ni se utiliza para inferir los contadores del resumen.

Las rutas principales son /splash, /login y /home. Detalle, llegada, finalización y términos se abren mediante navegación interna.

## Integraciones HTTP

Rutas relativas a cada base. La capitalización de los campos enviados se conserva conforme al código existente.

| Base | Método y ruta | Uso |
| --- | --- | --- |
| Principal | POST api/Ingreso | Acceso. |
| Principal | POST api/Consulta | Casos y resumen de actividad. |
| Principal | POST api/Aseguradoras | Aseguradoras del usuario. |
| Principal | POST api/ConfirmaLlegada | Registro de llegada. |
| Principal | POST api/ConcluirServicio | Finalización. |
| FlowConnect | GET api/consulta/dashboard | Indicadores. |
| FlowConnect | POST api/consulta/seguimiento | En camino. |
| FlowConnect | GET api/consulta/actividad-reciente | Últimos movimientos. |

FlowConnect envía X-Api-Key y Accept: application/json. Dashboard y actividad reciente envían usuario como parámetro de URL.

### Contratos consumidos

| Operación | Solicitud y respuesta utilizada |
| --- | --- |
| Ingreso | Envía tipo_proceso: 0, usuario, clave y nueva_clave vacía. Lee respuesta, tipo_usuario y nombre_usuario. |
| Consulta | Envía aseguradora, usuario, tipo_consulta, cedula, placa, nombre y nro_caso. Lee la lista Casos. El resumen consulta C y P. |
| Aseguradoras | Envía usuario. |
| En camino | Envía usuario, aseguradora como cadena, caso, estado: EnCamino y coordenadas. Evalúa mensaje y la confirmación «guardado correctamente». |
| Llegada | Envía Aseguradora, Usuario, Nro_Caso, Fecha_hora_llegada en ISO 8601 y Coordenadas. Espera respuesta: true. |
| Finalización | Envía Aseguradora, Usuario y Nro_Caso. Espera respuesta: true. |
| Dashboard | Lee pendientes, pendientes_hoy, finalizadas, finalizadas_semana y asignadas_count. |
| Actividad reciente | Lee un arreglo con id entero, titulo, estado y fecha válida. Conserva el orden del servidor. |

Ejemplo ilustrativo de actividad, sin datos de clientes:

    [
      {
        "id": 12345,
        "titulo": "Inspección #12345",
        "estado": "FINALIZADO",
        "fecha": "2026-09-26T10:30:00"
      }
    ]

La pantalla muestra el título y estado devueltos; no convierte ASEGURABLE en «En curso». La fecha se interpreta con DateTime.tryParse; si el servidor omite zona horaria, no se añade una zona artificial.

El ingreso actual no devuelve tokens. No se implementan OAuth, refresh token ni encabezado Bearer.

## Persistencia y errores

- La sesión guarda usuario, nombre y tipo en almacenamiento seguro.
- El progreso se guarda en preferencias por número de caso: assigned, enRoute, arrived y completed.
- Se mantienen lecturas compatibles con los indicadores de versiones anteriores.
- Las escrituras de progreso se serializan y no retroceden estados confirmados.
- Si el servidor confirma y falla el guardado local, el controlador conserva el resultado en memoria. Mientras ese proceso permanezca activo, el reintento repite únicamente el guardado.
- Cerrar sesión elimina la sesión; conserva los estados locales de los casos.
- Un 401 operativo de la API principal redirige al acceso. El ingreso maneja credenciales inválidas; FlowConnect mantiene su autorización independiente mediante API key.
- Actividad reciente tiene carga, error, reintento y lista vacía independientes del resumen.
- Finalizar invalida las consultas de inspecciones, dashboard y ambas secciones de actividad.

No hay cola de sincronización sin conexión. Si se pierde la respuesta remota o termina el proceso antes del guardado local, no se garantiza una operación exactamente una vez; resolverlo requiere conciliación o idempotencia del backend.

## Validación

Se utiliza flutter_lints. Para análisis estático:

    dart format --output=none --set-exit-if-changed lib
    flutter analyze

La validación funcional y en dispositivos corresponde al responsable del proyecto. No se agrega una automatización de pruebas de ejecución. La carpeta test/ no contiene una suite Dart; existe la plantilla nativa ios/RunnerTests/RunnerTests.swift.

Recorrido manual sugerido:

1. Acceso válido e inválido y recuperación de sesión.
2. Dashboard, filtros, aseguradoras y detalle.
3. GPS desactivado y permisos denegados o bloqueados.
4. En camino, llegada y finalización, con pulsaciones repetidas.
5. Cierre y reapertura después de cada estado confirmado.
6. Actividad reciente: título, estado y fecha iguales a la API; lista vacía y reintento.
7. Refresco de actividad al finalizar y al deslizar.
8. Pérdida de conexión, 401 operativo y cierre de sesión.

## Compilación

Configurar primero las claves locales y el entorno de destino:

    flutter build apk --release --dart-define-from-file=config/local.json
    flutter build appbundle --release --dart-define-from-file=config/local.json

En macOS, con el entorno iOS configurado:

    flutter build ios --release --dart-define-from-file=config/local.json

**Android usa actualmente la firma debug también en release.** Es necesario configurar la firma del titular antes de distribuir en tiendas. key.properties, certificados y almacenes de claves están excluidos de Git.

Para regenerar recursos definidos en pubspec.yaml:

    dart run flutter_native_splash:create
    dart run flutter_launcher_icons

## Preparación para GitHub

Se incluyen:

- .gitignore: credenciales, configuración local, IDE, cachés y compilaciones.
- .gitattributes: normalización de texto y tratamiento de recursos binarios.
- .editorconfig: formato básico compartido.
- Plantillas sin credenciales para Flutter, Android e iOS.
- pubspec.lock: resolución de dependencias versionada.

Si el directorio todavía no tiene repositorio:

    git init -b main

Antes del primer commit:

    git status --short
    git add .
    git diff --cached --stat
    git diff --cached
    git commit -m "Documentar y preparar SafeRisk Inspecciones"

Revisar que las configuraciones locales y claves no figuren entre los archivos preparados. Después de crear el repositorio vacío en GitHub, reemplazar la URL:

    git remote add origin https://github.com/ORGANIZACION/REPOSITORIO.git
    git push -u origin main

Son instrucciones de publicación: no se ha creado un repositorio remoto ni subido código durante esta preparación.

No se asignó una licencia de código abierto. El titular debe decidir las condiciones de uso antes de una publicación pública.

## Limitaciones conocidas

- Firma Android de producción sin configurar.
- Enlaces de Brokers con valores de ejemplo.
- Declaraciones nativas heredadas de permisos sin funcionalidad asociada.
- Sin cola offline, sincronización entre dispositivos ni garantía de idempotencia remota.
- El progreso local se identifica por número de caso, no por usuario o aseguradora; depende de la unicidad de ese número.
- El estado local no sustituye una conciliación completa con el backend.
- El resumen de actividad usa la API principal; la lista reciente usa FlowConnect.
- La configuración y compilación iOS requieren revisión en macOS.
