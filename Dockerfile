FROM jenkins/jenkins

USER root

RUN curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && python get-pip.py
RUN pip install -U ansible

USER jenkins