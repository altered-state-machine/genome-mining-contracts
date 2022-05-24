FROM public.ecr.aws/bitnami/node:16

WORKDIR /build

RUN ["npm", "install", "-g", "yarn"]

COPY . .

RUN ["yarn", "install", "--network-timeout 100000", "--frozen-lockfile"]

CMD [ "yarn" ]
