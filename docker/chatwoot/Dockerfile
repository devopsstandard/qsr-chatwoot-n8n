# ==========================================
# Production Non-Root Chatwoot Container
# ==========================================
FROM chatwoot/chatwoot:v3.13.0

USER root

# Create custom directory and copy entrypoint script
RUN mkdir -p /app/docker/chatwoot
COPY docker/chatwoot/entrypoint.sh /app/docker/chatwoot/entrypoint.sh
RUN chmod +x /app/docker/chatwoot/entrypoint.sh \
 && chown -R 10001:10001 /app/docker/chatwoot

USER 10001:10001

EXPOSE 3000

ENTRYPOINT ["/app/docker/chatwoot/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0", "-p", "3000"]
