FROM ubuntu:26.04

RUN useradd tester
USER tester:root
WORKDIR /script
COPY . .

RUN ["bash"]