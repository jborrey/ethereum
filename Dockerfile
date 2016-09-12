FROM python:2.7.12

WORKDIR /home
RUN git clone https://github.com/ethereum/serpent.git
WORKDIR /home/serpent
RUN make
RUN make install
RUN python setup.py install

WORKDIR /home
RUN git clone https://github.com/ethereum/pyethereum.git
WORKDIR /home/pyethereum
RUN python setup.py install

WORKDIR /home/ethereum
CMD ["/bin/bash"]
