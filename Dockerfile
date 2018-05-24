FROM prom/prometheus

ADD prometheus.yml /etc/prometheus/
ADD alerting_rules_*.yml /etc/prometheus/
