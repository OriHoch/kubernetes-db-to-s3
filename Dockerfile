FROM alpine:3.7
ENV CLOUD_SDK_VERSION 212.0.0

ENV PATH /google-cloud-sdk/bin:$PATH
ENV 
RUN apk --no-cache add \
        curl \
        python \
        py-crcmod \
        bash \
        libc6-compat \
        openssh-client \
        git \
    && curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar xzf google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm google-cloud-sdk-${CLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    ln -s /lib /lib64 && \
    gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image && \
    gcloud --version
RUN apk add --update --no-cache \
            libpq wget python-dev \
            postgresql-dev build-base \
            postgresql dcron ca-certificates \
            py-pip libffi-dev 
RUN pip install kubernetes psycopg2 s3cmd
COPY backup.py /
COPY crontab /etc/cron.d/do-backup
RUN chmod 0644 /etc/cron.d/do-backup
RUN touch /var/log/cron.log



# Run the command on container startup
#CMD python /backup.py && \
 #   crond -s /etc/cron.d -b -L /var/log/cron.log && \
  #  tail -f /var/log/cron.log
  CMD while true; do sleep 1; export MINIKUBE=true; done
VOLUME ["/root/.config"]
