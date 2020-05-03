(ns bastion.eni
  (:require [clojure.core.async :refer [<!! timeout]]
            [cognitect.aws.client.api :as aws]
            [bastion.clients :as clients]))

(defn- describe-network-interfaces
  [attachment-description]
  (println "Describing network interfaces for" attachment-description)
  (aws/invoke @clients/ec2
              {:op      :DescribeNetworkInterfaces
               :request {:Filters
                         [{:Name   "description"
                           :Values [attachment-description]}]}}))

(defn wait-for-deletion
  [attachment-description]
  (println "Waiting for ENI deletion")
  (loop [description (describe-network-interfaces attachment-description)]
    (let [network-interfaces (:NetworkInterfaces description)]
      (if (> (count network-interfaces) 0)
        (do
          (<!! (timeout 2000))
          (recur (describe-network-interfaces attachment-description)))))))

(defn get-public-ip
  [attachment-description]
  (println "Getting public IP for bastion")
  (loop [description (describe-network-interfaces attachment-description)]
    (let [network-interfaces (:NetworkInterfaces description)]
      (if-let [public-ip (get-in (first network-interfaces) [:Association :PublicIp])]
        public-ip
        (do
          (<!! (timeout 2000))                              ; ENI attachment & IP assignment may take some time
          (recur (describe-network-interfaces attachment-description)))))))
