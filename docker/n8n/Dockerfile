# ==========================================
# Production Non-Root n8n Container
# ==========================================
FROM n8nio/n8n:latest

USER root

# Create directory structure for custom node extensions
RUN mkdir -p /home/node/.n8n/custom-nodes \
 && chown -R node:node /home/node/.n8n

# Copy custom node definitions into n8n custom-nodes directory
COPY --chown=node:node docker/n8n/custom-nodes/ /home/node/.n8n/custom-nodes/

USER node

EXPOSE 5678

CMD ["start"]
