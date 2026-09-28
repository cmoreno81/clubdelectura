# 📚 Club de Lectura
Todos los cambios importantes del proyecto se documentarán en este fichero.

El formato está inspirado en Keep a Changelog y el versionado sigue Semantic Versioning.

---
## v0.9 Beta - 30/06/2026

### 🎉 Primera beta pública

#### Clubvisión
- Sistema de votaciones
- Gala
- Lectura actual
- Historial

#### Dashboard
- Resumen mensual
- Usuario del mes
- Mood
- Tendencias

#### Libros
- Alta de libros
- Estados de lectura
- Valoraciones

#### Ranking
- Clasificaciones del club

## 💜 Gracias

Primera beta probada por:

- Cristina
- Ana
- Bea
- Silvia
- ...

Gracias por todas las ideas, errores encontrados y propuestas de mejora.

---

# [0.9.1] - 2026-07-01

## ✨ Añadido

- Nuevo sistema de votación de Clubvisión desde la aplicación.
- Sincronización de votos entre dispositivos mediante validación en backend.
- Automatización del cierre mensual de Clubvisión.
- Historial de Clubvisión accesible desde la aplicación.
- Iconos de género en el listado de libros.
- Iconos de género en la ficha de detalle de cada libro.
- Utilidad compartida `genero_utils.dart` para centralizar los iconos de género.

## 🐞 Corregido

- Solucionado el error al cargar libros cuando algunos campos numéricos llegaban como enteros.
- Corregido el control de votos duplicados entre varios dispositivos.
- Corregido el mes mostrado en el historial de Clubvisión (problema de zona horaria).
- Corregido el orden del historial para mostrar primero las ediciones más recientes.
- Mejorado el tratamiento de errores de carga mediante una vista de error reutilizable.
- Blindados los modelos frente a valores nulos o tipos inesperados.

## 💄 Mejoras de experiencia de usuario

- Nuevo mensaje: "Nadie lo está leyendo en este momento."
- Mejor consistencia visual entre Clubvisión y la sección de Libros.
- Mayor claridad en la representación visual de los géneros.
- Preparación de la aplicación para futuras mejoras sin afectar a las versiones publicadas.

## 🏗️ Arquitectura

- Creación de la rama `develop`.
- Primera organización del proyecto mediante Roadmap, Backlog y Changelog.
- Inicio del flujo de trabajo basado en versiones y releases.

---

# [3.4.x] - 2026-09 (resumen desde la 0.9.1)

Entre la 0.9.1 y la 3.4.4 la aplicación pasó de ser un club único a soportar
varios clubes, clubes públicos e invitaciones, y se añadió todo el sistema
de Ligas. Este resumen agrupa lo más relevante; los detalles están en el
historial de commits de `develop`.

## ✨ Añadido

### Ligas de ClubReads
- Ligas entre clubes con temporadas de 14 días, 5 divisiones (Bronce →
  Diamante) y ascensos/descensos automáticos.
- Escalera de divisiones, tabla en vivo de cualquier división, podios y
  reto semanal con bonus.
- Histórico de temporadas anteriores y pestaña "Acumulado" con flechas de
  tendencia.
- Medallero personal con 12 medallas distintas (ascenso, podio, racha
  perfecta, polifacética, constancia, remontada, Libro del Año, Diamante,
  Bicampeona/Hattrick de Diamante...).
- Sala de Trofeos: palmarés de toda la comunidad y vitrina especial para el
  Libro de Oro, el premio anual único a la 1ª del ranking Acumulado.
- Leyenda de trofeos unificada entre "Cómo funciona la liga" y la Sala de
  Trofeos.

### Clubes
- Varios clubes por usuaria, clubes públicos, invitaciones y transferencia
  de propiedad de club.
- Clubvisión compartible entre clubes.
- Racha del club y "Club Wrapped".
- Eliminación de cuenta y flujo de moderación (reportar y bloquear
  contenido/comentarios).

### Mi espacio y Mis estadísticas
- Separación de "Mi espacio" y "Mis estadísticas" (antes mezclados en un
  Inicio personal).
- Gráfica de ritmo de lectura con fechas y barras tocables.
- Bingo lector: cartones de retos literarios marcados a mano, con logros e
  insignias propias.
- Reordenación de secciones (Libros favoritos y Mi libro del año antes de
  Celebra tu año) y carga de favoritos independiente del perfil.

### Navegación
- Menú inferior flotante unificado (antes distinto entre club y Global),
  persistente al navegar entre Catálogo/Ligas.
- Etiquetas largas del menú se encogen en vez de cortarse.

### Libros y Clubvisión
- Renombrado manual de capítulos.
- Papeleta de Clubvisión dinámica y opción de forzar una candidata a mano.
- Aviso cuando a un club le faltan candidatas.

## 🐞 Corregido
- Numerosos ajustes visuales: alineación de portadas de favoritos, hueco
  bajo la cuadrícula de "Mis estadísticas", temporada mostrada en el
  medallero, mes cortado en el historial de Clubvisión.
- Lenguaje neutro en los mensajes de bloqueo de cuentas.

## 🏗️ Arquitectura
- Preparación y envío a App Store/TestFlight además de Google Play.
- Cifrado y textos ajustados para la revisión de Apple.

---