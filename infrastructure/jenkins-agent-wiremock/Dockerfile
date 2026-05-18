# Wiremock como servicio HTTP mock (NO es un agente Jenkins).
# Sirve las mappings de test/wiremock/mappings/ en el puerto 8080 del contenedor.
FROM wiremock/wiremock:3.9.1

# Las mappings se montan como volumen desde el repo: ver docker-compose.yml.
EXPOSE 8080
CMD ["--verbose", "--global-response-templating"]
