(ns bastion.clients
  (:require [cognitect.aws.client.api :as aws]))

(def ec2 (delay (aws/client {:api :ec2})))
(def ecs (delay (aws/client {:api :ecs})))
