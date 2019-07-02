ARG FROM_IMAGE
FROM ${FROM_IMAGE}
USER 0
RUN chmod g=u /etc/passwd
COPY [--chown=0:0] entrypoint.sh /
RUN chmod +x entrypoint.sh

USER 10001
ENV HOME /home/user
WORKDIR /projects
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["sleep", "infinity"]
