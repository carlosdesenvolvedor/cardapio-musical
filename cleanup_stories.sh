#!/bin/bash

# Diretório onde os stories são armazenados (dentro do volume do MinIO ou mapeado)
STORIES_DIR="/path/to/minio/data/music-system-media/stories"

# Remove arquivos com mais de 720 minutos (12 horas)
find "$STORIES_DIR" -type f -mmin +720 -delete

# Log da operação
echo "$(date): Limpeza de stories concluída." >> /var/log/cleanup_stories.log
