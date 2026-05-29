FROM elixir:1.17.3-otp-27-slim

RUN apt-get update && apt-get install -y build-essential git bash
RUN mkdir -p /src/app

WORKDIR /src/app
RUN git clone https://github.com/rrcook/headline_maker.git
WORKDIR /src/app/headline_maker
RUN mix deps.get && mix compile

ENTRYPOINT ["mix", "run", "-e", "HeadlineMaker.main([\"-i\", \"bbs.retrocampus.com\", \"-f\", \"RetroCampusFeed\", \"-r\", \"511-1234\", \"-d\", \"./output\"])"]
