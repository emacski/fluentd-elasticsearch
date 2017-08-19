FROM ubuntu:17.10

# image metadata
LABEL image.name="k8s-fluentd" \
      image.maintainer="Erik Maciejewski <mr.emacski@gmail.com>"

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        ruby \
        ruby-dev \
        libjemalloc1 \
    # install redact
    && curl -L https://github.com/emacski/redact/releases/download/v0.2.0/redact -o /usr/bin/redact \
    && chmod +x /usr/bin/redact \
    # install fluentd
    && gem install --no-document oj -v 3.1.3 \
    && gem install --no-document fluentd -v 0.14.19 \
    && fluent-gem install --no-document fluent-plugin-kubernetes_metadata_filter -v 0.27.0 \
    && fluent-gem install --no-document fluent-plugin-elasticsearch -v 1.9.5 \
    && fluent-gem install --no-document fluent-plugin-systemd -v 0.3.0 \
    && mkdir -p /etc/fluent && mkdir -p /var/log/fluentd \
    # clean up
    && apt-get remove -y --auto-remove \
        build-essential \
        ruby-dev \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/gems/2.3.0/cache/*

ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.1

COPY . /

# build metadata
ARG GIT_URL=none
ARG GIT_COMMIT=none
LABEL build.git.url=$GIT_URL \
      build.git.commit=$GIT_COMMIT

ENTRYPOINT ["redact", "entrypoint", \
            "--default-tpl-path", "/fluent.conf.redacted", \
            "--default-cfg-path", "/etc/fluent/fluent.conf", \
            "--", \
            "root", "fluentd"]

CMD ["--log", "/var/log/fluentd.log"]
