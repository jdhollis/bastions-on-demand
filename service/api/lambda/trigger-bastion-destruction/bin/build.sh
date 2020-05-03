#!/usr/bin/env sh

lein clean && \
lein cljsbuild once && \
cat target/trigger-bastion-destruction/handler.js resources/export.js > target/trigger-bastion-destruction/index.js && \
mv target/trigger-bastion-destruction/index.js target/trigger-bastion-destruction/handler.js && \
cd target/trigger-bastion-destruction && \
zip -9qyr ../trigger-bastion-destruction.zip .
