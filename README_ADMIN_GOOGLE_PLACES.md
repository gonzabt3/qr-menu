# Herramienta de Relevamiento desde Google Places (Backoffice /admin)

Resumen:
- Usa Google Places API (Nearby Search + Place Details) para encontrar restaurantes alrededor de una coordenada.
- Guarda resultados en modelo Business y encola un job que descarga la web y busca menús e Instagram.
- Recomendado para uso administrado desde /admin (UI puede llamar al endpoint POST /admin/businesses con lat/lng/radius).

Pasos de configuración:
1. Activar Google Places API en Google Cloud Console y generar una API key.
2. Añadir la API key a las variables de entorno:
   - GOOGLE_PLACES_API_KEY
3. Correr migraciones:
   - rails db:migrate
4. Asegurarte de que Sidekiq/ActiveJob esté configurado para procesar jobs (FetchBusinessWebsiteJob).
5. Llamar al endpoint desde el admin (por ejemplo con fetch desde front) enviando lat, lng y radius.

Ejemplo curl:
```bash
curl -X POST "https://yourapp.example/admin/businesses" \
  -H "Content-Type: application/json" \
  -d '{"lat": -34.6037, "lng": -58.3816, "radius": 3000}'
```

Consideraciones legales y de uso:
- No scrapees Google Maps HTML; usa la API oficial (este ejemplo lo hace).
- Revisa las cuotas y costos en Google Cloud.
- Respeta robots.txt y tiempos entre requests cuando descargues websites de terceros.
