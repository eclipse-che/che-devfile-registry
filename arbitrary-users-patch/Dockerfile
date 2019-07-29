ARG FROM_IMAGE
FROM ${FROM_IMAGE}
USER 0
# Set permissions on /etc/passwd and /home to allow arbitrary users to write
RUN mkdir -p /home/user
RUN chgrp -R 0 /home
RUN chmod -R g=u /etc/passwd /home
COPY [--chown=0:0] entrypoint.sh /
RUN chmod +x /entrypoint.sh

USER 10001
ENV HOME=/home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["tail", "-f", "/dev/null"]
