FROM mysql:latest

RUN apt-get update -qq && apt-get install -y curl zip netcat cron

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \ 
    && ./aws/install --bin-dir /usr/bin && rm -Rf aws awscliv2.zip

COPY ./scripts /scripts
RUN chmod +x /scripts/*.sh

ENV CMS_HOST=cms
ENV MYSQL_DATABASE=exampledb
ENV MYSQL_PORT=3306
ENV MYSQL_USER=exampleuser
ENV MYSQL_PASSWORD=examplepass
ENV MYSQL_HOST=db

ENV BACKUP_HOST="https://s3.filebase.com"
ENV BACKUP_SCHEDULE="*/15 * * * *"
ENV BACKUP_RETAIN="6 hours"

COPY ./crontab /crontab

CMD /scripts/run.sh
ENTRYPOINT []
